terraform {
	required_version = ">=0.13"

	required_providers {
		archive = {
			source = "hashicorp/archive"
			version = "~> 2.0"
		}
		aws = {
			source  = "hashicorp/aws"
			version = "~> 3.0"
		}
	}
}

// 1) Provide your own access and secret keys so terraform can connect
//    and create AWS resources (e.g. our lambda function)
provider "aws" {
	access_key = "AKIA4D4DPLNC5ZVRZ4G5"
	secret_key = "r1XG19cbEphxbR/ksjfdAHXkCeaFd45mQBemV6z2"
	region="us-east-1"
}


// Create the soruce file as zip which is needed to be uploaded to S3 inorder to run the lambda in aws
data "archive_file" "zip" {
    // Directory that contain our index file
	source_dir =  "${path.module}/src"
	type = "zip"
    // Output directory of the zip
	output_path = "${path.module}/data/hello-world-lambda.zip"
}

// 4) Create an AWS IAM resource
data "aws_iam_policy_document" "mypolicy" {
	version = "2012-10-17"

	statement {
		// Let the IAM resource have temporary admin permissions to
		// add permissions for itself.
		// https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html
		actions = ["sts:AssumeRole"]
		effect = "Allow"
		principals {
			identifiers = ["lambda.amazonaws.com"]
			type = "Service"
		}
	}
}

// Create a IAM resource in AWS which is given the permissions detail in our above policy document
resource "aws_iam_role" "myRole" {
	assume_role_policy = data.aws_iam_policy_document.mypolicy.json
}

// Create the lambda function in AWS and upload our .zip with our code to it
resource "aws_lambda_function" "myFunction" {
	function_name = "hello-world-lambda"
	handler = "index.handler"
	runtime = "nodejs16.x"
	timeout = 6

	// Upload the .zip file Terraform created to AWS
	filename = "data/hello-world-lambda.zip"
	source_code_hash = data.archive_file.zip.output_base64sha256

	// Connect our IAM resource to our lambda function in AWS
	role = aws_iam_role.myRole.arn
}