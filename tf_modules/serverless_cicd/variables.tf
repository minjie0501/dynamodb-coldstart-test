variable "project" {
  type        = string
  description = "Name of the project to be deployed"
}

variable "name_prefix" {
  type        = string
  description = "Name prefix containing the project name and environment"
}

variable "nodejs_version" {
  default     = "18.15.0"
  description = "Node.js version to use in CodeBuild. Will be used in this url https://nodejs.org/dist/v{var.nodejs_version}/node-v{var.nodejs_version}-linux-x64.tar.gz"
}

variable "branches" {
  default = {
    "stag" = "develop"
    "prod" = "main"
  }
  description = "Map of branches for each environment"
}

# Custom resource names
variable "s3_builds_bucket" {
  default     = ""
  type        = string
  description = "Custom resource name for the S3 builds bucket."
}
variable "iam_role_codepipeline" {
  default     = ""
  type        = string
  description = "Custom resource name for the IAM CodePipeline role."
}

variable "iam_role_codebuild" {
  default     = ""
  type        = string
  description = "Custom resource name for the IAM CodeBuild role."
}

variable "iam_policy_codepipeline" {
  default     = ""
  type        = string
  description = "Custom resource name for the IAM CodePipeline policy."
}
variable "iam_policy_codebuild" {
  default     = ""
  type        = string
  description = "Custom resource name for the IAM CodeBuild policy."
}

variable "iam_policy_codebuild_extra_policy" {
  default     = ""
  type        = string
  description = "Extra/Custom CodeBuild policies for the generated codebuild IAM role"
}

variable "codebuild_project_tests" {
  default     = ""
  type        = string
  description = "Custom resource name for the tests CodeBuild project"
}
variable "codebuild_project_plan" {
  default     = ""
  type        = string
  description = "Custom resource name for the plan CodeBuild project"
}
variable "codebuild_project_apply" {
  default     = ""
  type        = string
  description = "Custom resource name for the apply CodeBuild project"
}
variable "codebuild_project_deploy" {
  default     = ""
  type        = string
  description = "Custom resource name for the deploy CodeBuild project"
}
variable "aws_codepipeline" {
  default     = ""
  type        = string
  description = "Custom resource name for this CodePipeline"
}

variable "custom_tags" {
  default     = null
  type        = map(string)
  description = "(optional) Custom tags to attach to AWS resources"
}

variable "cloudwatch_event_deploy_failed" {
  default     = null
  type        = string
  description = "Name for the CloudWatch Event used for when the deploy step fails"
}
variable "cloudwatch_event_deploy_failed_lambda_arn" {
  default     = null
  type        = string
  description = "ARN for the lambda to trigger when the CP Deploy step failed"
}

variable "db_migration_lambda_arn" {
  default     = null
  type        = string
  description = "ARN for the migration lambda which runs during the Deploy stage"
}
variable "db_migration_lambda_name" {
  default     = null
  type        = string
  description = "Name for the migration lambda which runs during the Deploy stage"
}

variable "codestar_bitbucket_connection_arn" {
  type        = string
  description = "Codestar connection ARN for Bitbucket access"
}

variable "bitbucket_repository" {
  type        = string
  description = "Bitbucket repository name"
}


locals {
  env                = terraform.workspace
  branch             = var.branches[local.env]
  source_s3_key      = "${var.project}/${local.branch}.zip"
  workspace_var_file = "./tf_vars/${local.env}.tfvars"

  full_repository_id = "appstrakt/${var.bitbucket_repository}"

  # Allow overriding the resource names
  s3_builds_bucket = var.s3_builds_bucket != "" ? var.s3_builds_bucket : "${var.name_prefix}-builds"

  iam_role_codepipeline = var.iam_role_codepipeline != "" ? var.iam_role_codepipeline : "${var.name_prefix}-codepipeline"
  iam_role_codebuild    = var.iam_role_codebuild != "" ? var.iam_role_codebuild : "${var.name_prefix}-codebuild"

  iam_policy_codepipeline = var.iam_policy_codepipeline != "" ? var.iam_policy_codepipeline : "CodePipeline"
  iam_policy_codebuild    = var.iam_policy_codebuild != "" ? var.iam_policy_codebuild : "CodeBuild"

  iam_policy_codebuild_extra_policy = var.iam_policy_codebuild_extra_policy != "" ? ",\n${var.iam_policy_codebuild_extra_policy}" : ""

  codebuild_project_plan   = var.codebuild_project_plan != "" ? var.codebuild_project_plan : "${var.name_prefix}-terraform-plan"
  codebuild_project_apply  = var.codebuild_project_apply != "" ? var.codebuild_project_apply : "${var.name_prefix}-terraform-apply"
  codebuild_project_tests  = var.codebuild_project_tests != "" ? var.codebuild_project_tests : "${var.name_prefix}-tests"
  codebuild_project_deploy = var.codebuild_project_deploy != "" ? var.codebuild_project_deploy : "${var.name_prefix}-serverless-deploy"

  aws_codepipeline = var.aws_codepipeline != "" ? var.aws_codepipeline : var.name_prefix

  migration_foreach         = var.db_migration_lambda_name == null ? [] : [var.db_migration_lambda_name]
  migration_count           = var.db_migration_lambda_name == null ? 0 : 1
  codebuild_policy_resource = var.db_migration_lambda_name == null ? "*" : "${var.db_migration_lambda_arn}/*"
}
