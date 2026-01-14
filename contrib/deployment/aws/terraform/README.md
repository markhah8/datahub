# DataHub on AWS EKS - Terraform Module

This Terraform module deploys a complete DataHub infrastructure on AWS EKS.

## What This Creates

- VPC with public and private subnets across 3 availability zones
- EKS cluster with managed node group
- EBS CSI driver addon for persistent storage
- IAM roles and policies for EKS and DataHub components
- Security groups for cluster access
- AWS Load Balancer Controller prerequisites

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- kubectl
- helm 3.x

## Usage

### Basic Deployment

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and customize:

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your preferred values
```

2. Initialize and apply Terraform:

```bash
terraform init
terraform plan
terraform apply
```

3. Configure kubectl:

```bash
aws eks update-kubeconfig --region <your-region> --name <cluster-name>
```

4. Deploy DataHub using Helm:

```bash
# Add DataHub Helm repository
helm repo add datahub https://helm.datahubproject.io
helm repo update

# Deploy DataHub
helm install datahub datahub/datahub --values datahub-values.yaml
```

## Variables

| Name | Description | Default | Required |
|------|-------------|---------|----------|
| cluster_name | Name of the EKS cluster | datahub-eks | no |
| region | AWS region | us-west-2 | no |
| cluster_version | Kubernetes version | 1.28 | no |
| node_instance_type | EC2 instance type for nodes | m5.large | no |
| node_count | Number of nodes in the node group | 3 | no |

See `variables.tf` for all available variables.

## Post-Deployment Steps

After Terraform completes:

1. **Install AWS Load Balancer Controller** (required for ingress):

```bash
# Create IAM service account
eksctl create iamserviceaccount \
  --cluster=datahub-eks \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess \
  --override-existing-serviceaccounts \
  --approve

# Install the controller
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \
  --set clusterName=datahub-eks \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  -n kube-system
```

2. **Deploy DataHub**: Follow the instructions in the main [AWS deployment guide](../../../../docs/deploy/aws.md)

## Using AWS Managed Services

To use RDS, OpenSearch, and MSK instead of running storage in Kubernetes:

1. Set `enable_managed_services = true` in `terraform.tfvars`
2. Run `terraform apply`
3. Use the output values to configure your DataHub Helm values

## Outputs

- `cluster_endpoint` - EKS cluster endpoint
- `cluster_name` - EKS cluster name
- `cluster_security_group_id` - Security group ID for the cluster
- `region` - AWS region
- `vpc_id` - VPC ID
- `rds_endpoint` - (if enabled) RDS endpoint
- `opensearch_endpoint` - (if enabled) OpenSearch endpoint
- `msk_bootstrap_brokers` - (if enabled) MSK bootstrap brokers

## Cleanup

To destroy all resources:

```bash
# First, delete DataHub helm release
helm uninstall datahub

# Then destroy infrastructure
terraform destroy
```

## Cost Estimation

Running this configuration will incur costs for:
- EKS cluster: ~$73/month
- 3 x m5.large EC2 instances: ~$200/month
- EBS volumes: ~$10-50/month
- Load Balancer: ~$20/month
- Data transfer: Variable

**Total estimated cost: $300-400/month** (excluding managed services)

With managed services (RDS, OpenSearch, MSK), add approximately:
- RDS db.t3.medium: ~$60/month
- OpenSearch t3.medium: ~$100/month
- MSK (3 brokers): ~$360/month

## Support

For issues or questions:
- Check the main [AWS deployment documentation](../../../../docs/deploy/aws.md)
- Ask in the [DataHub Slack](https://datahub.com/slack)
- Open an issue on [GitHub](https://github.com/datahub-project/datahub/issues)
