# Deployment Helper Scripts

This directory contains automation scripts for deploying and managing DataHub on AWS.

## Scripts

### deploy.sh

Automated deployment script that:
1. Checks prerequisites (terraform, aws, kubectl, helm, eksctl)
2. Deploys infrastructure with Terraform
3. Configures kubectl
4. Installs AWS Load Balancer Controller
5. Deploys DataHub via Helm

**Usage:**
```bash
./deploy.sh
```

**Prerequisites:**
- AWS CLI configured with credentials
- Terraform installed
- kubectl installed
- Helm 3 installed
- eksctl installed

### cleanup.sh

Cleanup script that:
1. Uninstalls DataHub Helm release
2. Destroys Terraform infrastructure

**Usage:**
```bash
./cleanup.sh
```

**Warning:** This will delete all resources. Make sure you want to proceed before running.

## Manual Deployment

If you prefer manual control over the deployment process, follow these steps:

### 1. Deploy Infrastructure

```bash
cd ../terraform
terraform init
terraform plan
terraform apply
```

### 2. Configure kubectl

```bash
aws eks update-kubeconfig --region <region> --name <cluster-name>
kubectl get nodes
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
  --cluster=<cluster-name> \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::<account-id>:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve

# Install controller
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \
  --set clusterName=<cluster-name> \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  -n kube-system
```

### 4. Deploy DataHub

```bash
helm repo add datahub https://helm.datahubproject.io
helm repo update
helm install datahub datahub/datahub --values ../terraform/datahub-values.yaml
```

### 5. Monitor Deployment

```bash
kubectl get pods -w
kubectl get ingress
```

## Troubleshooting

### Pods not starting
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Ingress not working
```bash
kubectl describe ingress
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

### Terraform errors
```bash
terraform plan  # Check what will be created/modified
terraform refresh  # Sync state with actual resources
```

## Support

For issues or questions:
- Check the [main documentation](../../../../docs/deploy/aws.md)
- Ask in [DataHub Slack](https://datahub.com/slack)
- Open an issue on [GitHub](https://github.com/datahub-project/datahub/issues)
