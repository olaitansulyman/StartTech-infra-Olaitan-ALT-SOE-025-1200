terraform {
  required_version = ">= 1.0"
  
  backend "s3" {
    key            = "state/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~> 1.10.0"
    }
  }
}

# --- Providers ---
provider "aws" {
  region = var.aws_region
}

provider "mongodbatlas" {
  public_key  = var.mongodb_atlas_public_key
  private_key = var.mongodb_atlas_private_key
}

# --- Data Sources ---
data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

# --- MongoDB Atlas Logic ---
resource "mongodbatlas_project" "starttech" {
  name   = var.project_name
  org_id = var.mongodb_atlas_org_id
}

resource "mongodbatlas_advanced_cluster" "main" {
  project_id   = mongodbatlas_project.starttech.id
  name         = "${var.project_name}-cluster"
  cluster_type = "REPLICASET"

  replication_specs {
    num_shards = 1
    region_configs {
      priority      = 7
      provider_name = "AWS"
      region_name   = "US_EAST_1"
      electable_specs {
        instance_size = "M0"
        node_count    = 3
      }
      read_only_specs {
        instance_size = "M0"
        node_count    = 0
      }
    }
  }
}



resource "mongodbatlas_database_user" "db_user" {
  username           = "admin"
  password           = var.mongodb_atlas_password
  project_id         = mongodbatlas_project.starttech.id
  auth_database_name = "admin"

  roles {
    role_name     = "readWriteAnyDatabase"
    database_name = "admin"
  }
}

# --- Infrastructure Modules ---

module "networking" {
  source = "./modules/networking"
  
  vpc_cidr             = var.vpc_cidr
  availability_zones   = data.aws_availability_zones.available.names
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  
  tags = var.tags
}

module "compute" {
  source = "./modules/compute"
  
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  private_subnet_ids    = module.networking.private_subnet_ids
  
  instance_type         = var.instance_type
  min_size              = var.min_size
  max_size              = var.max_size
  desired_capacity      = var.desired_capacity
  
  tags = var.tags
}

module "storage" {
  source                    = "./modules/storage"
  bucket_name               = "starttech-frontend-${var.project_name}-${data.aws_caller_identity.current.account_id}"
  vpc_id                    = module.networking.vpc_id
  private_subnet_ids        = module.networking.private_subnet_ids
  backend_security_group_id = module.compute.backend_security_group_id
  tags                      = var.tags
}

module "monitoring" {
  source = "./modules/monitoring"
  
  log_group_name = var.log_group_name
  tags           = var.tags
}

# --- ElastiCache Redis ---
resource "aws_security_group" "redis" {
  name_prefix = "${var.project_name}-redis-"
  vpc_id      = module.networking.vpc_id
  
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [module.compute.backend_security_group_id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = var.tags
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.project_name}-redis-subnet-group"
  subnet_ids = module.networking.private_subnet_ids
  
  tags = var.tags
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "${var.project_name}-redis"
  description                = "Redis cluster for ${var.project_name}"
  engine                     = "redis"
  engine_version             = "7.0"
  node_type                  = "cache.t3.micro"
  num_cache_clusters         = 2
  automatic_failover_enabled = true
  port                       = 6379
  
  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis.id]
  
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  transit_encryption_mode    = "preferred"
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-redis"
  })
}
