variable "project" {
  default     = "dynamo_coldstart"
  type        = string
  description = "Name of the project repo to be deployed"
}
locals {
  env         = terraform.workspace
  name_prefix = "${var.project}-${local.env}"
  custom_tags = {
    "project"     = "dynamo-coldstart"
    "environment" = terraform.workspace
  }
}
