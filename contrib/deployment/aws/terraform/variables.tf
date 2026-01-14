variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "datahub-eks"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway (cheaper but not HA)"
  type        = bool
  default     = true
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS nodes"
  type        = string
  default     = "m5.large"
}

variable "node_count" {
  description = "Desired number of nodes in the EKS node group"
  type        = number
  default     = 3
}

variable "node_min_count" {
  description = "Minimum number of nodes in the EKS node group"
  type        = number
  default     = 2
}

variable "node_max_count" {
  description = "Maximum number of nodes in the EKS node group"
  type        = number
  default     = 5
}

variable "node_capacity_type" {
  description = "Capacity type for nodes (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "enable_managed_services" {
  description = "Enable AWS managed services (RDS, OpenSearch, MSK)"
  type        = bool
  default     = false
}

variable "rds_instance_class" {
  description = "RDS instance class (only used if enable_managed_services = true)"
  type        = string
  default     = "db.t3.medium"
}

variable "opensearch_instance_type" {
  description = "OpenSearch instance type (only used if enable_managed_services = true)"
  type        = string
  default     = "t3.medium.search"
}

variable "msk_instance_type" {
  description = "MSK broker instance type (only used if enable_managed_services = true)"
  type        = string
  default     = "kafka.m5.large"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
