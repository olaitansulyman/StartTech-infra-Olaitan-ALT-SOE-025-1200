#!/bin/bash
set -e

echo "=== Terraform Validation ==="
cd terraform
terraform validate

echo "=== Planning ==="
terraform plan -out=tfplan

echo "=== State Check ==="
terraform state list

echo "✅ All checks passed!"
