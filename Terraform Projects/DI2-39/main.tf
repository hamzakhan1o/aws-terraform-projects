provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "s3-bucket-backend" {
  bucket = var.s3_bucket_name
}

resource "aws_s3_bucket_versioning" "s3-bucket-backend-versioning" {
  bucket = aws_s3_bucket.s3-bucket-backend.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "terraform_folder" {
  bucket = aws_s3_bucket.s3-bucket-backend.id
  key    = "terraform_backend/"
}

resource "aws_codecommit_repository" "infra-vpc-codecommit-repo" {
  repository_name = var.codecommit_repository_name
  description = "CodeCommit Repository to store VPC infra terraform codes."
}

#iam role for codebuild 

data "aws_iam_policy_document" "codebuild-policy-document" {
    statement{
        actions = ["logs:*"]
        resources = ["*"]
        effect = "Allow"
    }
    statement{
        actions = ["s3:*"]
        resources = [
          "${aws_s3_bucket.s3-bucket-backend.arn}/*",
          "${aws_s3_bucket.s3-bucket-backend.arn}"
        ]
        effect = "Allow"
    }
}

resource "aws_iam_policy" "codebuild-policy" {
    name = var.codebuild_policy_name
    path = "/"
    policy = data.aws_iam_policy_document.codebuild-policy-document.json
}

resource "aws_iam_role" "codebuild-role" {
  name = var.codebuild_role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "codebuild-policy-attachment1" {
    policy_arn  = aws_iam_policy.codebuild-policy.arn
    role        = aws_iam_role.codebuild-role.id
}

resource "aws_iam_role_policy_attachment" "codebuild-policy-attachment2" {
    policy_arn  = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
    role        = aws_iam_role.codebuild-role.id
}