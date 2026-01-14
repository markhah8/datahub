#!/bin/bash
# DataHub AWS Cleanup Script
# This script helps cleanup DataHub deployment and AWS resources

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Function to cleanup DataHub
cleanup_datahub() {
    print_info "Removing DataHub installation..."
    
    if helm list | grep -q datahub; then
        helm uninstall datahub
        print_info "DataHub uninstalled successfully."
    else
        print_warning "DataHub installation not found."
    fi
    
    # Wait for resources to be cleaned up
    print_info "Waiting for Kubernetes resources to be cleaned up..."
    sleep 30
}

# Function to cleanup infrastructure
cleanup_infrastructure() {
    print_info "Destroying infrastructure with Terraform..."
    
    cd "$TERRAFORM_DIR"
    
    if [ ! -d ".terraform" ]; then
        print_error "Terraform not initialized. Nothing to cleanup."
        exit 1
    fi
    
    terraform destroy -auto-approve
    
    print_info "Infrastructure destroyed successfully!"
    cd - > /dev/null
}

# Main execution
main() {
    echo "====================================="
    echo "  DataHub AWS Cleanup Script"
    echo "====================================="
    echo ""
    
    print_warning "This will delete ALL DataHub resources and infrastructure!"
    read -p "Are you sure you want to continue? (yes/no): " -r
    
    if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
        print_info "Cleanup cancelled."
        exit 0
    fi
    
    cleanup_datahub
    cleanup_infrastructure
    
    print_info "Cleanup complete!"
}

# Run main function
main
