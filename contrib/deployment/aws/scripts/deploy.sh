#!/bin/bash
# DataHub AWS Deployment Helper Script
# This script helps deploy DataHub on AWS EKS using Terraform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
CLUSTER_NAME="datahub-eks"
REGION="us-west-2"
TERRAFORM_DIR="../terraform"

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    local missing_tools=()
    
    if ! command -v terraform &> /dev/null; then
        missing_tools+=("terraform")
    fi
    
    if ! command -v aws &> /dev/null; then
        missing_tools+=("aws")
    fi
    
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi
    
    if ! command -v helm &> /dev/null; then
        missing_tools+=("helm")
    fi
    
    if ! command -v eksctl &> /dev/null; then
        missing_tools+=("eksctl")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        echo "Please install the missing tools and try again."
        exit 1
    fi
    
    print_info "All prerequisites are installed."
}

# Function to initialize and deploy infrastructure
deploy_infrastructure() {
    print_info "Deploying infrastructure with Terraform..."
    
    cd "$TERRAFORM_DIR"
    
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found. Creating from example..."
        cp terraform.tfvars.example terraform.tfvars
        print_warning "Please edit terraform.tfvars with your configuration and run this script again."
        exit 1
    fi
    
    print_info "Initializing Terraform..."
    terraform init
    
    print_info "Planning infrastructure changes..."
    terraform plan
    
    read -p "Do you want to apply these changes? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
        print_info "Deployment cancelled."
        exit 0
    fi
    
    print_info "Applying Terraform configuration..."
    terraform apply -auto-approve
    
    # Get outputs
    CLUSTER_NAME=$(terraform output -raw cluster_name)
    REGION=$(terraform output -raw region)
    
    print_info "Infrastructure deployed successfully!"
    cd - > /dev/null
}

# Function to configure kubectl
configure_kubectl() {
    print_info "Configuring kubectl..."
    aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"
    
    print_info "Verifying cluster access..."
    kubectl get nodes
}

# Function to install AWS Load Balancer Controller
install_alb_controller() {
    print_info "Installing AWS Load Balancer Controller..."
    
    # Download IAM policy
    if [ ! -f "iam_policy.json" ]; then
        print_info "Downloading IAM policy..."
        curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
    fi
    
    # Get AWS account ID
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    
    # Create IAM policy (will fail if already exists, which is fine)
    print_info "Creating IAM policy..."
    aws iam create-policy \
        --policy-name AWSLoadBalancerControllerIAMPolicy \
        --policy-document file://iam_policy.json \
        2>/dev/null || print_warning "IAM policy already exists, skipping creation."
    
    # Create service account
    print_info "Creating IAM service account..."
    eksctl create iamserviceaccount \
        --cluster="$CLUSTER_NAME" \
        --namespace=kube-system \
        --name=aws-load-balancer-controller \
        --attach-policy-arn=arn:aws:iam::"$ACCOUNT_ID":policy/AWSLoadBalancerControllerIAMPolicy \
        --override-existing-serviceaccounts \
        --approve
    
    # Install controller
    print_info "Installing ALB controller via Helm..."
    helm repo add eks https://aws.github.io/eks-charts
    helm repo update
    helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \
        --set clusterName="$CLUSTER_NAME" \
        --set serviceAccount.create=false \
        --set serviceAccount.name=aws-load-balancer-controller \
        -n kube-system
    
    print_info "AWS Load Balancer Controller installed successfully!"
}

# Function to deploy DataHub
deploy_datahub() {
    print_info "Deploying DataHub..."
    
    # Add DataHub Helm repo
    helm repo add datahub https://helm.datahubproject.io
    helm repo update
    
    # Check if values file exists
    if [ ! -f "$TERRAFORM_DIR/datahub-values.yaml" ]; then
        print_error "DataHub values file not found at $TERRAFORM_DIR/datahub-values.yaml"
        exit 1
    fi
    
    print_info "Installing DataHub via Helm..."
    helm install datahub datahub/datahub --values "$TERRAFORM_DIR/datahub-values.yaml"
    
    print_info "DataHub installation initiated. It may take several minutes for all pods to be ready."
    print_info "You can monitor the status with: kubectl get pods"
}

# Function to display deployment info
show_info() {
    print_info "Deployment complete!"
    echo ""
    echo "Next steps:"
    echo "1. Wait for all pods to be ready: kubectl get pods -w"
    echo "2. Check ingress status: kubectl get ingress"
    echo "3. Access DataHub at the ingress endpoint"
    echo ""
    echo "Useful commands:"
    echo "  kubectl get pods                    # Check pod status"
    echo "  kubectl logs <pod-name>             # View pod logs"
    echo "  helm list                           # List Helm releases"
    echo "  kubectl get ingress                 # Get ingress endpoint"
}

# Main execution
main() {
    echo "====================================="
    echo "  DataHub AWS Deployment Script"
    echo "====================================="
    echo ""
    
    check_prerequisites
    deploy_infrastructure
    configure_kubectl
    install_alb_controller
    deploy_datahub
    show_info
}

# Run main function
main
