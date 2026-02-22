#!/bin/bash
set -e

echo "🧹 Starting teardown..."

# Check if cluster exists
CLUSTER_EXISTS=$(aws eks describe-cluster --name eks-game-eks-cluster --region eu-west-2 2>/dev/null && echo "true" || echo "false")

if [ "$CLUSTER_EXISTS" = "true" ]; then
    echo "Cluster found. Cleaning up Kubernetes resources..."

    # Delete all ingresses first (triggers ExternalDNS cleanup)
    echo "Deleting all ingresses..."
    kubectl delete ingress --all --all-namespaces --ignore-not-found=true 2>/dev/null || true

    # Delete LoadBalancer services
    echo "Deleting LoadBalancer services..."
    kubectl delete svc ingress-nginx-controller -n ingress-nginx --ignore-not-found=true 2>/dev/null || true
    kubectl get svc --all-namespaces --field-selector spec.type=LoadBalancer -o json 2>/dev/null | jq -r '.items[] | "\(.metadata.namespace) \(.metadata.name)"' | while read ns name; do
        echo "  Deleting service: $name in namespace $ns"
        kubectl delete svc "$name" -n "$ns" --ignore-not-found=true 2>/dev/null || true
    done

    # Delete ArgoCD CRDs
    echo "Cleaning up ArgoCD CRDs..."
    kubectl get crd 2>/dev/null | grep argoproj | awk '{print $1}' | xargs kubectl delete crd --ignore-not-found=true 2>/dev/null || true

    echo "⏳ Waiting 3 minutes for AWS to cleanup LoadBalancers and ENIs..."
    sleep 180
else
    echo "Cluster not found. Skipping kubectl cleanup..."
fi

# Force delete any remaining NLBs
echo "Checking for remaining NLBs..."
NLB_COUNT=$(aws elbv2 describe-load-balancers --region eu-west-2 2>/dev/null | jq -r '[.LoadBalancers[] | select(.LoadBalancerName | contains("k8s"))] | length' 2>/dev/null || echo "0")

if [ "$NLB_COUNT" -gt 0 ]; then
    echo "Found $NLB_COUNT NLB(s). Deleting..."
    aws elbv2 describe-load-balancers --region eu-west-2 2>/dev/null | \
    jq -r '.LoadBalancers[] | select(.LoadBalancerName | contains("k8s")) | .LoadBalancerArn' | \
    while read -r lb_arn; do
        echo "  Deleting NLB: $lb_arn"
        aws elbv2 delete-load-balancer --region eu-west-2 --load-balancer-arn "$lb_arn" 2>/dev/null || true
    done

    echo "⏳ Waiting 2 minutes for NLB deletion..."
    sleep 120
else
    echo "No NLBs found"
fi

# Get VPC ID and Zone ID before destroy
echo "Getting VPC and Route53 zone info..."
VPC_ID=$(terraform show -json 2>/dev/null | jq -r '.values.root_module.child_modules[] | select(.address=="module.vpc") | .resources[] | select(.type=="aws_vpc") | .values.id' 2>/dev/null || echo "")
ZONE_ID=$(terraform output -raw route53_zone_id 2>/dev/null || \
          terraform show -json 2>/dev/null | jq -r '.values.root_module.child_modules[] | select(.address=="module.route53") | .resources[] | select(.type=="aws_route53_zone") | .values.zone_id' 2>/dev/null || \
          aws route53 list-hosted-zones --query "HostedZones[?Name=='eks.hamsa-ahmed.co.uk.'].Id" --output text 2>/dev/null | cut -d'/' -f3)

# Delete DNS records
if [ -n "$ZONE_ID" ]; then
    echo "Found zone: $ZONE_ID - Force deleting DNS records..."
    aws route53 list-resource-record-sets --hosted-zone-id "$ZONE_ID" 2>/dev/null | \
    jq -c '.ResourceRecordSets[] | select(.Type != "NS" and .Type != "SOA")' 2>/dev/null | \
    while read -r record; do
        RECORD_NAME=$(echo "$record" | jq -r '.Name')
        RECORD_TYPE=$(echo "$record" | jq -r '.Type')
        echo "  Deleting: $RECORD_NAME ($RECORD_TYPE)"
        aws route53 change-resource-record-sets \
            --hosted-zone-id "$ZONE_ID" \
            --change-batch "{\"Changes\":[{\"Action\":\"DELETE\",\"ResourceRecordSet\":$record}]}" \
            2>/dev/null || true
    done
    echo "DNS cleanup complete"
fi

# Run terraform destroy
echo "Running terraform destroy..."
terraform destroy -auto-approve

# If destroy failed, aggressive cleanup
if [ $? -ne 0 ]; then
    echo "⚠️  Destroy failed. Performing aggressive cleanup..."

    # Delete any remaining ENIs in VPC
    if [ -n "$VPC_ID" ]; then
        echo "Deleting network interfaces in VPC: $VPC_ID"
        aws ec2 describe-network-interfaces --region eu-west-2 --filters "Name=vpc-id,Values=$VPC_ID" --query 'NetworkInterfaces[*].NetworkInterfaceId' --output text | \
        xargs -n1 -I {} bash -c 'echo "  Deleting ENI: {}"; aws ec2 delete-network-interface --region eu-west-2 --network-interface-id {} 2>/dev/null || true'
    fi

    # Double-check for any remaining NLBs
    echo "Double-checking for remaining NLBs..."
    aws elbv2 describe-load-balancers --region eu-west-2 2>/dev/null | \
    jq -r '.LoadBalancers[] | select(.LoadBalancerName | contains("k8s")) | .LoadBalancerArn' | \
    while read -r lb_arn; do
        if [ -n "$lb_arn" ]; then
            echo "  Force deleting NLB: $lb_arn"
            aws elbv2 delete-load-balancer --region eu-west-2 --load-balancer-arn "$lb_arn" 2>/dev/null || true
        fi
    done

    echo "⏳ Waiting 90 seconds before retry..."
    sleep 90

    echo "Retrying terraform destroy..."
    terraform destroy -auto-approve
fi

echo "✅ Teardown complete!"tf
