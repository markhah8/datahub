output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "rds_endpoint" {
  description = "RDS endpoint (if enabled)"
  value       = var.enable_managed_services ? try(aws_db_instance.datahub[0].endpoint, null) : null
}

output "opensearch_endpoint" {
  description = "OpenSearch endpoint (if enabled)"
  value       = var.enable_managed_services ? try(aws_opensearch_domain.datahub[0].endpoint, null) : null
}

output "msk_bootstrap_brokers" {
  description = "MSK bootstrap brokers (if enabled)"
  value       = var.enable_managed_services ? try(aws_msk_cluster.datahub[0].bootstrap_brokers, null) : null
}
