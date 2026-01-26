#!/bin/bash

set -e

ROLLBACK_TYPE=${1:-"backend"}

echo "🔄 StartTech Rollback - $ROLLBACK_TYPE"

# Check if outputs.json exists
if [ ! -f "outputs.json" ]; then
    echo "❌ outputs.json not found. Please run deploy-infrastructure.sh first."
    exit 1
fi

case $ROLLBACK_TYPE in
    "backend")
        echo "🔄 Rolling back backend deployment..."
        
        ASG_NAME=$(jq -r '.autoscaling_group_name.value' outputs.json 2>/dev/null || echo "starttech-backend-asg")
        
        # Cancel any ongoing instance refresh
        echo "⏹️ Cancelling ongoing instance refresh..."
        aws autoscaling cancel-instance-refresh --auto-scaling-group-name $ASG_NAME || true
        
        # Get previous launch template version
        LAUNCH_TEMPLATE_ID=$(aws autoscaling describe-auto-scaling-groups \
            --auto-scaling-group-names $ASG_NAME \
            --query 'AutoScalingGroups[0].LaunchTemplate.LaunchTemplateId' \
            --output text)
        
        CURRENT_VERSION=$(aws autoscaling describe-auto-scaling-groups \
            --auto-scaling-group-names $ASG_NAME \
            --query 'AutoScalingGroups[0].LaunchTemplate.Version' \
            --output text)
        
        if [ "$CURRENT_VERSION" = "\$Latest" ]; then
            LATEST_VERSION=$(aws ec2 describe-launch-template-versions \
                --launch-template-id $LAUNCH_TEMPLATE_ID \
                --query 'LaunchTemplateVersions[0].VersionNumber' \
                --output text)
            PREVIOUS_VERSION=$((LATEST_VERSION - 1))
        else
            PREVIOUS_VERSION=$((CURRENT_VERSION - 1))
        fi
        
        if [ $PREVIOUS_VERSION -lt 1 ]; then
            echo "❌ No previous version available for rollback"
            exit 1
        fi
        
        echo "🔄 Rolling back to launch template version $PREVIOUS_VERSION..."
        
        # Update ASG to use previous version
        aws autoscaling update-auto-scaling-group \
            --auto-scaling-group-name $ASG_NAME \
            --launch-template LaunchTemplateId=$LAUNCH_TEMPLATE_ID,Version=$PREVIOUS_VERSION
        
        # Start instance refresh with previous version
        aws autoscaling start-instance-refresh \
            --auto-scaling-group-name $ASG_NAME \
            --preferences MinHealthyPercentage=50,InstanceWarmup=300
        
        echo "⏳ Waiting for rollback to complete..."
        aws autoscaling wait instance-refresh-successful --auto-scaling-group-name $ASG_NAME
        
        echo "✅ Backend rollback complete!"
        ;;
        
    "frontend")
        echo "🔄 Rolling back frontend deployment..."
        
        BUCKET_NAME=$(jq -r '.frontend_bucket_name.value' outputs.json)
        DISTRIBUTION_ID=$(jq -r '.cloudfront_distribution_id.value' outputs.json)
        
        # List S3 versions (if versioning is enabled)
        echo "📋 Available S3 object versions:"
        aws s3api list-object-versions --bucket $BUCKET_NAME --prefix index.html --query 'Versions[?IsLatest==`false`].[Key,VersionId,LastModified]' --output table || echo "No previous versions found"
        
        echo "⚠️ Manual rollback required for frontend:"
        echo "1. Restore previous version from S3 bucket: $BUCKET_NAME"
        echo "2. Invalidate CloudFront cache: $DISTRIBUTION_ID"
        echo ""
        echo "Commands:"
        echo "aws s3 cp s3://$BUCKET_NAME/index.html s3://$BUCKET_NAME/index.html --version-id <VERSION_ID>"
        echo "aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths '/*'"
        ;;
        
    "infrastructure")
        echo "🔄 Rolling back infrastructure..."
        echo "⚠️ Infrastructure rollback requires manual intervention:"
        echo "1. Review terraform state"
        echo "2. Revert to previous terraform configuration"
        echo "3. Run terraform plan and apply"
        echo ""
        echo "cd terraform && terraform plan"
        ;;
        
    *)
        echo "❌ Invalid rollback type. Use: backend, frontend, or infrastructure"
        exit 1
        ;;
esac

echo "✅ Rollback process complete!"