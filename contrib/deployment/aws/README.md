# DataHub AWS Deployment Examples

This directory contains infrastructure-as-code examples and automation scripts for deploying DataHub on AWS.

## Contents

- **terraform/** - Terraform modules for deploying DataHub on AWS EKS
- **cloudformation/** - AWS CloudFormation templates for DataHub infrastructure
- **scripts/** - Helper scripts for deployment automation

## Prerequisites

Before using these deployment examples, ensure you have:

1. AWS CLI installed and configured with appropriate credentials
2. kubectl installed for Kubernetes management
3. Helm 3 installed for deploying DataHub
4. Terraform (for Terraform examples) or AWS CLI (for CloudFormation)
5. eksctl installed for EKS cluster management

## Quick Start

### Option 1: Terraform Deployment

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

See [terraform/README.md](terraform/README.md) for detailed instructions.

### Option 2: CloudFormation Deployment

```bash
cd cloudformation
aws cloudformation create-stack \
  --stack-name datahub-infrastructure \
  --template-body file://datahub-eks-stack.yaml \
  --capabilities CAPABILITY_IAM
```

See [cloudformation/README.md](cloudformation/README.md) for detailed instructions.

## Architecture Overview

These examples create:

1. **EKS Cluster** - Managed Kubernetes cluster with 3 nodes
2. **VPC and Networking** - Isolated VPC with public/private subnets
3. **IAM Roles** - Necessary service accounts and policies
4. **Load Balancer** - Application Load Balancer for frontend access
5. **Storage Options** - Examples for using AWS managed services (RDS, OpenSearch, MSK)

## Cost Considerations

The default configuration creates:
- 3 x m5.large EC2 instances (can be adjusted)
- Application Load Balancer
- EBS volumes for persistent storage

Estimated monthly cost: $200-$400 depending on region and usage.

For production, consider using managed services (RDS, OpenSearch, MSK) which will increase costs but reduce operational overhead.

## Support and Documentation

- Main deployment guide: [docs/deploy/aws.md](../../../docs/deploy/aws.md)
- Helm charts repository: https://github.com/acryldata/datahub-helm
- DataHub documentation: https://docs.datahub.com/

## Contributing

These examples are maintained by the community. If you have improvements or alternative deployment patterns, please contribute via pull request.
