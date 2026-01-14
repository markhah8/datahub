# Optional: Terraform configuration for AWS managed services
# This file is only applied if enable_managed_services = true

# RDS MySQL Database
resource "aws_db_subnet_group" "datahub" {
  count      = var.enable_managed_services ? 1 : 0
  name       = "${var.cluster_name}-db-subnet"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "${var.cluster_name}-db-subnet"
  }
}

resource "aws_security_group" "rds" {
  count       = var.enable_managed_services ? 1 : 0
  name        = "${var.cluster_name}-rds-sg"
  description = "Security group for DataHub RDS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [module.eks.cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-rds-sg"
  }
}

resource "random_password" "rds" {
  count   = var.enable_managed_services ? 1 : 0
  length  = 16
  special = true
}

resource "aws_secretsmanager_secret" "rds_password" {
  count       = var.enable_managed_services ? 1 : 0
  name        = "${var.cluster_name}-rds-password"
  description = "RDS password for DataHub"
}

resource "aws_secretsmanager_secret_version" "rds_password" {
  count         = var.enable_managed_services ? 1 : 0
  secret_id     = aws_secretsmanager_secret.rds_password[0].id
  secret_string = random_password.rds[0].result
}

resource "aws_db_instance" "datahub" {
  count                  = var.enable_managed_services ? 1 : 0
  identifier             = "${var.cluster_name}-mysql"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.rds_instance_class
  allocated_storage      = 100
  storage_type           = "gp3"
  db_name                = "datahub"
  username               = "datahub"
  password               = random_password.rds[0].result
  db_subnet_group_name   = aws_db_subnet_group.datahub[0].name
  vpc_security_group_ids = [aws_security_group.rds[0].id]
  skip_final_snapshot    = true
  multi_az               = false

  tags = {
    Name = "${var.cluster_name}-mysql"
  }
}

# OpenSearch Domain
resource "aws_security_group" "opensearch" {
  count       = var.enable_managed_services ? 1 : 0
  name        = "${var.cluster_name}-opensearch-sg"
  description = "Security group for DataHub OpenSearch"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [module.eks.cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-opensearch-sg"
  }
}

resource "aws_opensearch_domain" "datahub" {
  count       = var.enable_managed_services ? 1 : 0
  domain_name = "${var.cluster_name}-opensearch"
  engine_version = "OpenSearch_2.11"

  cluster_config {
    instance_type  = var.opensearch_instance_type
    instance_count = 3
    zone_awareness_enabled = true
    zone_awareness_config {
      availability_zone_count = 3
    }
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 100
    volume_type = "gp3"
  }

  vpc_options {
    subnet_ids         = slice(module.vpc.private_subnets, 0, 3)
    security_group_ids = [aws_security_group.opensearch[0].id]
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  advanced_security_options {
    enabled                        = false
    internal_user_database_enabled = false
  }

  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "es:*"
        Resource = "arn:aws:es:${var.region}:${data.aws_caller_identity.current.account_id}:domain/${var.cluster_name}-opensearch/*"
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-opensearch"
  }
}

# MSK Cluster
resource "aws_security_group" "msk" {
  count       = var.enable_managed_services ? 1 : 0
  name        = "${var.cluster_name}-msk-sg"
  description = "Security group for DataHub MSK"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 9092
    to_port         = 9092
    protocol        = "tcp"
    security_groups = [module.eks.cluster_security_group_id]
  }

  ingress {
    from_port       = 2181
    to_port         = 2181
    protocol        = "tcp"
    security_groups = [module.eks.cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-msk-sg"
  }
}

resource "aws_msk_cluster" "datahub" {
  count              = var.enable_managed_services ? 1 : 0
  cluster_name       = "${var.cluster_name}-kafka"
  kafka_version      = "3.5.1"
  number_of_broker_nodes = 3

  broker_node_group_info {
    instance_type   = var.msk_instance_type
    client_subnets  = slice(module.vpc.private_subnets, 0, 3)
    security_groups = [aws_security_group.msk[0].id]

    storage_info {
      ebs_storage_info {
        volume_size = 100
      }
    }
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "TLS_PLAINTEXT"
      in_cluster    = true
    }
  }

  tags = {
    Name = "${var.cluster_name}-kafka"
  }
}
