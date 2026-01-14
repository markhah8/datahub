# DataHub on AWS - Quick Start Guide

This is a comprehensive quick start guide for deploying DataHub on AWS EKS.

## Overview

This guide will help you deploy a production-ready DataHub instance on AWS using:
- Amazon EKS (Elastic Kubernetes Service)
- AWS Application Load Balancer
- Either in-cluster storage (MySQL, Elasticsearch, Kafka) or AWS managed services (RDS, OpenSearch, MSK)

**Estimated time:** 30-45 minutes

**Estimated cost:** $300-400/month for basic setup, $800-1000/month with managed services

## Prerequisites

Before starting, ensure you have:

1. **AWS Account** with appropriate permissions to create:
   - EKS clusters
   - VPCs and networking components
   - IAM roles and policies
   - EC2 instances
   - Load balancers

2. **Tools installed:**
   ```bash
   # Check if tools are installed
   terraform --version  # Should be >= 1.0
   aws --version        # AWS CLI v2
   kubectl version      # Kubernetes CLI
   helm version         # Helm 3.x
   eksctl version       # eksctl for EKS management
   ```

3. **AWS credentials configured:**
   ```bash
   aws configure
   # Enter your AWS Access Key ID, Secret Access Key, and default region
   ```

4. **Domain name (optional but recommended):**
   - A domain or subdomain for accessing DataHub (e.g., datahub.example.com)
   - SSL certificate in AWS ACM for HTTPS access

## Deployment Options

### Option A: Automated Deployment (Recommended for Getting Started)

Use the provided automation script for a one-command deployment:

```bash
cd scripts
./deploy.sh
```

This script will:
1. Check prerequisites
2. Deploy infrastructure with Terraform
3. Configure kubectl
4. Install AWS Load Balancer Controller
5. Deploy DataHub via Helm

**Time:** ~30 minutes

### Option B: Terraform Deployment (Recommended for Production)

For more control over the deployment:

```bash
cd terraform

# 1. Configure your deployment
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings

# 2. Deploy infrastructure
terraform init
terraform plan
terraform apply

# 3. Configure kubectl
aws eks update-kubeconfig --region us-west-2 --name datahub-eks

# 4. Follow post-deployment steps in terraform/README.md
```

**Time:** ~35 minutes

### Option C: CloudFormation Deployment

For AWS-native infrastructure as code:

```bash
cd cloudformation

# 1. Review and customize parameters.json

# 2. Create the stack
aws cloudformation create-stack \
  --stack-name datahub-eks \
  --template-body file://datahub-eks-cluster.yaml \
  --parameters file://parameters.json \
  --capabilities CAPABILITY_IAM \
  --region us-west-2

# 3. Wait for completion
aws cloudformation wait stack-create-complete \
  --stack-name datahub-eks \
  --region us-west-2

# 4. Follow post-deployment steps in cloudformation/README.md
```

**Time:** ~40 minutes

## Post-Deployment

### 1. Verify Cluster

```bash
kubectl get nodes
kubectl get pods
```

### 2. Get DataHub URL

```bash
kubectl get ingress
```

The ADDRESS column shows your load balancer endpoint.

### 3. Access DataHub

If using a custom domain:
1. Create a CNAME record pointing your domain to the load balancer endpoint
2. Wait for DNS propagation (5-30 minutes)
3. Access DataHub at https://your-domain.com

If not using a domain, access DataHub directly at the load balancer endpoint.

### 4. Login

Default credentials (change immediately in production):
- Username: `datahub`
- Password: `datahub`

## Configuration Options

### Using AWS Managed Services

For production deployments, consider using AWS managed services instead of running storage in Kubernetes:

**With Terraform:**
```hcl
# In terraform.tfvars
enable_managed_services = true
```

**Benefits:**
- Automated backups
- Automatic patching
- High availability
- Reduced operational overhead

**Additional cost:** ~$520/month

### Customizing DataHub

Edit the Helm values file before deployment:

```bash
# Edit terraform/datahub-values.yaml

# Key configurations:
# - Ingress hostname
# - SSL certificate ARN
# - Resource limits
# - Storage classes
# - Authentication settings
```

## Monitoring and Troubleshooting

### Check Pod Status

```bash
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Check Ingress

```bash
kubectl get ingress
kubectl describe ingress datahub-datahub-frontend
```

### Check Load Balancer Controller

```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

### Common Issues

**Pods stuck in Pending:**
- Check node resources: `kubectl describe nodes`
- Verify EBS CSI driver: `kubectl get pods -n kube-system | grep ebs`

**Ingress not created:**
- Verify ALB controller is running: `kubectl get pods -n kube-system | grep aws-load-balancer-controller`
- Check ingress annotations in values file

**Cannot connect to database:**
- Verify security groups allow traffic from EKS nodes
- Check connection strings in Helm values

## Scaling

### Scale Nodes

```bash
# With Terraform
terraform apply -var="node_count=5"

# With eksctl
eksctl scale nodegroup --cluster=datahub-eks --name=datahub-node-group --nodes=5
```

### Scale DataHub Components

```bash
# Edit Helm values
# Increase replicas for specific components
helm upgrade datahub datahub/datahub --values datahub-values.yaml
```

## Backup and Restore

### Backup Strategy

1. **Database backups:**
   - If using RDS: Automated daily snapshots (enabled by default)
   - If using MySQL pod: Set up backup jobs

2. **Elasticsearch/OpenSearch snapshots:**
   - Configure snapshot repository to S3
   - Schedule regular snapshots

3. **Kafka:**
   - If using MSK: Point-in-time recovery available
   - If using Kafka pod: Consider data replication

### Restore Procedure

Refer to DataHub documentation for detailed restore procedures:
https://docs.datahub.com/

## Cleanup

To delete all resources:

```bash
# Option 1: Use cleanup script
cd scripts
./cleanup.sh

# Option 2: Manual Terraform
cd terraform
helm uninstall datahub
terraform destroy

# Option 3: Manual CloudFormation
helm uninstall datahub
aws cloudformation delete-stack --stack-name datahub-eks
```

**Warning:** This will permanently delete all data. Ensure you have backups if needed.

## Cost Optimization

### Development/Testing

For non-production use:
- Use `t3.large` instances instead of `m5.large`
- Set `node_count = 2` instead of 3
- Use single NAT gateway (already default)
- Consider SPOT instances: `node_capacity_type = "SPOT"`

**Estimated savings:** 40-60% reduction

### Production

For production with managed services:
- Use Multi-AZ RDS for high availability
- Enable OpenSearch Multi-AZ with 3 nodes
- Use MSK with 3 brokers across AZs
- Set up CloudWatch monitoring
- Enable automated backups

## Security Best Practices

1. **Network Security:**
   - Keep databases in private subnets
   - Use security groups to restrict access
   - Enable VPC flow logs

2. **Authentication:**
   - Enable metadata service authentication
   - Use AWS IAM for ingestion sources
   - Rotate credentials regularly

3. **Encryption:**
   - Enable encryption at rest for RDS/OpenSearch/MSK
   - Use HTTPS with valid SSL certificate
   - Enable encryption in transit

4. **Access Control:**
   - Use IAM roles instead of access keys
   - Enable IRSA (IAM Roles for Service Accounts)
   - Follow principle of least privilege

## Next Steps

After deployment:

1. **Configure ingestion:**
   - Set up ingestion sources
   - Configure UI-based ingestion with appropriate IAM roles

2. **Set up users and groups:**
   - Create user accounts
   - Configure authentication (SSO/OIDC)
   - Set up authorization policies

3. **Customize metadata:**
   - Add business glossary terms
   - Create domains
   - Set up tags and documentation

4. **Monitor:**
   - Set up CloudWatch alarms
   - Configure DataHub telemetry
   - Monitor resource usage

## Support

- **Documentation:** https://docs.datahub.com/
- **Slack Community:** https://datahub.com/slack
- **GitHub Issues:** https://github.com/datahub-project/datahub/issues
- **AWS Deployment Guide:** See main documentation at `/docs/deploy/aws.md`

## Additional Resources

- [DataHub Architecture](https://docs.datahub.com/docs/architecture/architecture)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [DataHub Helm Chart](https://github.com/acryldata/datahub-helm)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
