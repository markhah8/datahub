# DataHub on AWS EKS - CloudFormation Templates

This directory contains AWS CloudFormation templates for deploying DataHub on EKS.

## What This Creates

- VPC with public and private subnets
- EKS cluster with managed node group
- IAM roles and policies
- Security groups
- EBS CSI driver

## Prerequisites

- AWS CLI configured with appropriate credentials
- kubectl
- helm 3.x
- eksctl (for easier IAM service account management)

## Deployment Steps

### 1. Create the EKS Cluster

```bash
aws cloudformation create-stack \
  --stack-name datahub-eks \
  --template-body file://datahub-eks-cluster.yaml \
  --parameters file://parameters.json \
  --capabilities CAPABILITY_IAM \
  --region us-west-2
```

Wait for the stack to complete:

```bash
aws cloudformation wait stack-create-complete \
  --stack-name datahub-eks \
  --region us-west-2
```

### 2. Configure kubectl

```bash
aws eks update-kubeconfig \
  --region us-west-2 \
  --name datahub-eks
```

### 3. Install AWS Load Balancer Controller

```bash
# Download IAM policy
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json

# Create IAM policy
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

# Create service account
eksctl create iamserviceaccount \
  --cluster=datahub-eks \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::<ACCOUNT-ID>:policy/AWSLoadBalancerControllerIAMPolicy \
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

### 4. Deploy DataHub

```bash
# Add DataHub Helm repo
helm repo add datahub https://helm.datahubproject.io
helm repo update

# Deploy DataHub
helm install datahub datahub/datahub --values ../terraform/datahub-values.yaml
```

## Parameters

You can customize the deployment by modifying `parameters.json`:

```json
[
  {
    "ParameterKey": "ClusterName",
    "ParameterValue": "datahub-eks"
  },
  {
    "ParameterKey": "KubernetesVersion",
    "ParameterValue": "1.28"
  },
  {
    "ParameterKey": "NodeInstanceType",
    "ParameterValue": "m5.large"
  },
  {
    "ParameterKey": "NodeGroupDesiredCapacity",
    "ParameterValue": "3"
  }
]
```

## Stack Outputs

After deployment, the stack provides these outputs:

- **ClusterName**: EKS cluster name
- **ClusterEndpoint**: EKS API endpoint
- **VpcId**: VPC ID
- **SubnetIds**: Subnet IDs for the cluster

## Cleanup

To delete all resources:

```bash
# First, delete DataHub
helm uninstall datahub

# Delete the CloudFormation stack
aws cloudformation delete-stack --stack-name datahub-eks --region us-west-2
```

## Cost Estimation

Similar to the Terraform deployment:
- EKS cluster: ~$73/month
- 3 x m5.large EC2 instances: ~$200/month
- EBS volumes: ~$10-50/month
- Load Balancer: ~$20/month

**Total: ~$300-400/month**

## Support

For issues or questions:
- Check the [AWS deployment documentation](../../../../docs/deploy/aws.md)
- Ask in the [DataHub Slack](https://datahub.com/slack)
- Open an issue on [GitHub](https://github.com/datahub-project/datahub/issues)
