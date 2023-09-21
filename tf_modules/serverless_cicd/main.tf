data "aws_iam_role" "terraform" {
  name = "terraform"
}

data "local_file" "assume_role_script" {
  filename = "${path.module}/assume-role.sh"
}

resource "aws_s3_bucket" "builds" {
  bucket = local.s3_builds_bucket
  tags   = var.custom_tags
}

resource "aws_s3_bucket_acl" "builds_acl" {
  bucket     = aws_s3_bucket.builds.id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.builds_acl_ownership]
}

resource "aws_s3_bucket_ownership_controls" "builds_acl_ownership" {
  bucket = aws_s3_bucket.builds.id
  rule {
    object_ownership = "ObjectWriter"
  }
}


resource "aws_s3_bucket_lifecycle_configuration" "builds_lifecycle" {
  bucket = aws_s3_bucket.builds.bucket

  rule {
    id = "builds_lifecycle"

    expiration {
      days = 30
    }

    filter {}

    status = "Enabled"
  }
}

resource "aws_iam_role" "codepipeline" {
  name = local.iam_role_codepipeline

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline" {
  name = local.iam_policy_codepipeline
  role = aws_iam_role.codepipeline.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "${aws_s3_bucket.builds.arn}",
        "${aws_s3_bucket.builds.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "lambda:InvokeFunction",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "codestar-connections:UseConnection",
      "Resource": "${var.codestar_bitbucket_connection_arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role" "codebuild" {
  name = local.iam_role_codebuild

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codebuild" {
  name = local.iam_policy_codebuild
  role = aws_iam_role.codebuild.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "${aws_s3_bucket.builds.arn}/*"
    },
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "${data.aws_iam_role.terraform.arn}"
    },
    {
      "Effect": "Allow",
      "Action": "lambda:InvokeFunction",
      "Resource": "${local.codebuild_policy_resource}"
    }
    ${local.iam_policy_codebuild_extra_policy}
  ]
}
EOF
}

resource "aws_codebuild_project" "tests" {
  name         = local.codebuild_project_tests
  service_role = aws_iam_role.codebuild.arn
  tags         = var.custom_tags

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type = "CODEPIPELINE"

    buildspec = <<EOF
      version: 0.2
      phases:
        install:
          commands:
            - npm install
        build:
          commands:
            - make test
      artifacts:
        files:
        - '**/*'
    EOF
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    type         = "ARM_CONTAINER"
    image        = "public.ecr.aws/docker/library/node:${var.nodejs_version}"
  }
}
resource "aws_codebuild_project" "terraform_plan" {
  name         = local.codebuild_project_plan
  service_role = aws_iam_role.codebuild.arn
  tags         = var.custom_tags

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type = "CODEPIPELINE"

    buildspec = <<EOF
version: 0.2
phases:
  install:
    commands:
    - |
      wget https://raw.githubusercontent.com/warrensbox/terraform-switcher/release/install.sh
      chmod 755 install.sh
      ./install.sh -b ./.bin
      rm install.sh
      .bin/tfswitch -b .bin/terraform
      .bin/terraform -v
    -  >-
      echo ${base64encode(data.local_file.assume_role_script.content)}
      | base64 -d > /assume-role && chmod +x /assume-role
  build:
    commands:
    - mkdir -p build/
    - >-
      sh /assume-role ${data.aws_iam_role.terraform.arn} tf-init-${var.name_prefix}
      .bin/terraform init
    - .bin/terraform workspace select $ENV
    - .bin/terraform plan -var-file ${local.workspace_var_file} -out build/terraform.tfplan
artifacts:
  files:
  - '**/*'
EOF
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    type         = "LINUX_CONTAINER"
    image        = "aws/codebuild/standard:7.0"

    environment_variable {
      name  = "ENV"
      value = local.env
    }
  }
}

resource "aws_codebuild_project" "terraform_apply" {
  name         = local.codebuild_project_apply
  service_role = aws_iam_role.codebuild.arn
  tags         = var.custom_tags

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type = "CODEPIPELINE"

    buildspec = <<EOF
version: 0.2
phases:
  install:
    commands:
    - |
      wget https://raw.githubusercontent.com/warrensbox/terraform-switcher/release/install.sh
      chmod 755 install.sh
      ./install.sh -b ./.bin
      rm install.sh
      .bin/tfswitch -b .bin/terraform
      .bin/terraform -v
  build:
    commands:
    - .bin/terraform workspace select $ENV
    - .bin/terraform apply build/terraform.tfplan
    - .bin/terraform output -json | jq 'with_entries(.value |= .value)' > build/terraform-outputs.json
artifacts:
  files:
  - '**/*'
EOF
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    type         = "LINUX_CONTAINER"
    image        = "aws/codebuild/standard:7.0"

    environment_variable {
      name  = "ENV"
      value = local.env
    }
  }
}

resource "aws_codebuild_project" "serverless_deploy" {
  name         = local.codebuild_project_deploy
  service_role = aws_iam_role.codebuild.arn
  tags         = var.custom_tags

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type = "CODEPIPELINE"

    buildspec = <<EOF
version: 0.2
phases:
  install:
    runtime-versions:
      nodejs: 18
    commands:
    - >-
      echo ${base64encode(data.local_file.assume_role_script.content)}
      | base64 -d > /usr/local/bin/assume-role && chmod +x /usr/local/bin/assume-role
  build:
    commands:
    - "export PATH=\"/root/.local/bin:$PATH\""
    - npm ci
    - >-
      assume-role ${data.aws_iam_role.terraform.arn} sls-${var.name_prefix}
      npx serverless deploy --stage $ENV
EOF
  }

  environment {
    compute_type = "BUILD_GENERAL1_MEDIUM"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "ENV"
      value = local.env
    }

    environment_variable {
      name  = "NODE_OPTIONS"
      value = "--max-old-space-size=4096"
    }
  }
}

resource "aws_codepipeline" "codepipeline" {
  name     = local.aws_codepipeline
  role_arn = aws_iam_role.codepipeline.arn
  tags     = var.custom_tags

  artifact_store {
    location = aws_s3_bucket.builds.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        BranchName           = local.branch
        ConnectionArn        = var.codestar_bitbucket_connection_arn
        FullRepositoryId     = local.full_repository_id
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Tests"
      category         = "Build"
      provider         = "CodeBuild"
      owner            = "AWS"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["tests_output"]

      configuration = {
        ProjectName = aws_codebuild_project.tests.name
      }
    }

    action {
      name             = "TerraformPlan"
      category         = "Build"
      provider         = "CodeBuild"
      owner            = "AWS"
      version          = "1"
      input_artifacts  = ["tests_output"]
      output_artifacts = ["terraform_plan_output"]
      run_order        = 2

      configuration = {
        ProjectName = aws_codebuild_project.terraform_plan.name
      }
    }
  }

  stage {
    name = "Approval"

    action {
      name     = "ManualApproval"
      category = "Approval"
      provider = "Manual"
      owner    = "AWS"
      version  = "1"
    }
  }

  stage {
    name = "Deploy"

    action {
      name             = "TerraformApply"
      category         = "Build"
      provider         = "CodeBuild"
      owner            = "AWS"
      version          = "1"
      input_artifacts  = ["terraform_plan_output"]
      output_artifacts = ["terraform_apply_output"]
      run_order        = 1

      configuration = {
        ProjectName = aws_codebuild_project.terraform_apply.name
      }
    }

    action {
      name            = "ServerlessDeploy"
      category        = "Build"
      provider        = "CodeBuild"
      owner           = "AWS"
      version         = "1"
      input_artifacts = ["terraform_apply_output"]
      run_order       = 2

      configuration = {
        ProjectName = aws_codebuild_project.serverless_deploy.name
      }
    }

    dynamic "action" {
      for_each = local.migration_foreach

      content {
        category  = "Invoke"
        name      = "RunCustomLambda"
        owner     = "AWS"
        provider  = "Lambda"
        version   = "1"
        run_order = 3

        configuration = {
          FunctionName   = var.db_migration_lambda_name
          UserParameters = "{\"action\": \"upgrade\" }"
        }
      }
    }
  }
}

resource "aws_cloudwatch_event_rule" "deploy_failed" {
  count       = local.migration_count
  name        = var.cloudwatch_event_deploy_failed
  description = "Capture a CodePipeline deploy stage failure"

  event_pattern = <<PATTERN
    {
      "source": [
        "aws.codepipeline"
      ],
      "detail-type": [
        "CodePipeline Stage Execution State Change"
      ],
      "detail": {
        "state": [
          "FAILED"
        ]
      }
    }
  PATTERN
}

resource "aws_cloudwatch_event_target" "sns" {
  count = local.migration_count
  rule  = aws_cloudwatch_event_rule.deploy_failed[0].name
  arn   = var.cloudwatch_event_deploy_failed_lambda_arn
}
