terraform {
  required_version = "= 1.2.3"
  backend "s3" {
    role_arn       = "arn:aws:iam::1234567890:role/terraform"
    region         = "eu-west-1"
    bucket         = "dynamo-coldstart-terraform-state" # TODO: manually create this bucket
    key            = "dynamo-coldstart/terraform.tfstate"
    dynamodb_table = "dynamo-coldstart-terraform-locks" # TODO: manually create this table
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.19"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
  default_tags {
    tags = local.custom_tags
  }
  assume_role {
    role_arn = "arn:aws:iam::1234567890:role/terraform"
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "serverless_cicd" {
    source                            = "./tf_modules/serverless_cicd"
    project                           = var.project
    name_prefix                       = local.name_prefix
    # Node version should be compatible with https://nodejs.org/dist/v${nodejs_version}/node-v${nodejs_version}-linux-x64.tar.gz
    nodejs_version                    = "18.17.1"
    codestar_bitbucket_connection_arn = ""
    bitbucket_repository              = "dynamo_coldstart"
    branches                          = {
        "stag" = "develop"
        "prod" = "main"
    }

    
}

output "custom_tags" {
  value = local.custom_tags
}

# TODO: replace/remove example output
output "example_output" {
  value = module.serverless_cicd.example
}
