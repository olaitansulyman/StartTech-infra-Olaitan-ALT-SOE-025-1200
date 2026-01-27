terraform {
  required_version = ">= 1.0"
  
  backend "s3" {
    bucket         = "your-unique-terraform-state-bucket" 
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

  replication_specs = [
    {
      num_shards = 1
      region_configs = [
        {
          priority      = 7
          provider_name = "AWS"
          region_name   = "US_EAST_1"
          electable_specs = {
            instance_size = "M0"
          }
        }
      ]
    }
  ]
}



resource "mongodbatlas_database_user" "db_user" {
  username           = "admin"
  password           = "password123" 
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
  bucket_name               = "starttech-frontend-${var.project_name}"
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
