#!/bin/bash
yum update -y
yum install -y docker amazon-cloudwatch-agent

# Start Docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/starttech-app.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}/app.log"
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

# Create application directory
mkdir -p /opt/starttech
cd /opt/starttech

# Create a simple health check endpoint
cat > /opt/starttech/health-server.py << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import json
from datetime import datetime

class HealthHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = {
                'status': 'healthy',
                'timestamp': datetime.now().isoformat(),
                'service': 'starttech-backend'
            }
            self.wfile.write(json.dumps(response).encode())
        else:
            self.send_response(404)
            self.end_headers()

PORT = 8080
with socketserver.TCPServer(("", PORT), HealthHandler) as httpd:
    print(f"Server running on port {PORT}")
    httpd.serve_forever()
EOF

chmod +x /opt/starttech/health-server.py

# Create systemd service
cat > /etc/systemd/system/starttech-backend.service << 'EOF'
[Unit]
Description=StartTech Backend Service
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/starttech
ExecStart=/usr/bin/python3 /opt/starttech/health-server.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Start the service
systemctl daemon-reload
systemctl enable starttech-backend
systemctl start starttech-backend