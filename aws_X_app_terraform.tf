provider "aws" {
  region = "us-east-1"
}

# VPC Configuration
resource "aws_vpc" "notification_service_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Notification_Service_VPC"
  }
}

resource "aws_vpc" "input_service_vpc" {
  cidr_block = "10.1.0.0/16"
  tags = {
    Name = "Input_Service_VPC"
  }
}

resource "aws_vpc" "timeline_service_vpc" {
  cidr_block = "10.2.0.0/16"
  tags = {
    Name = "Timeline_Service_VPC"
  }
}

resource "aws_vpc" "search_service_vpc" {
  cidr_block = "10.3.0.0/16"
  tags = {
    Name = "Search_Service_VPC"
  }
}

# Transit Gateway
resource "aws_ec2_transit_gateway" "main" {
  description = "Transit Gateway for VPC interconnections"
  tags = {
    Name = "Main_Transit_Gateway"
  }
}

# VPC Attachments to Transit Gateway
resource "aws_ec2_transit_gateway_vpc_attachment" "notification_attachment" {
  subnet_ids         = ["subnet-id1"] # Replace with actual subnet ID
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.notification_service_vpc.id
}

# Lambda Functions
resource "aws_lambda_function" "analytics_lambda" {
  function_name = "analytics_lambda"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"

  # Replace with your zip file location
  filename = "path/to/analytics_lambda.zip"

  environment {
    variables = {
      ENV = "production"
    }
  }
}

resource "aws_lambda_function" "compute_lambda" {
  function_name = "compute_lambda"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"

  # Replace with your zip file location
  filename = "path/to/compute_lambda.zip"

  environment {
    variables = {
      ENV = "production"
    }
  }
}

# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_execution_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# S3 Buckets
resource "aws_s3_bucket" "data_bucket" {
  bucket = "data-storage-bucket"
  acl    = "private"

  tags = {
    Name        = "DataBucket"
    Environment = "Production"
  }
}

# Kinesis Stream
resource "aws_kinesis_stream" "data_stream" {
  name             = "data-stream"
  shard_count      = 1
  retention_period = 24

  tags = {
    Environment = "production"
  }
}

# Cognito
resource "aws_cognito_user_pool" "user_pool" {
  name = "user-pool"

  tags = {
    Environment = "production"
  }
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  name         = "user-pool-client"
  user_pool_id = aws_cognito_user_pool.user_pool.id
}

# ElastiCache
resource "aws_elasticache_cluster" "redis_cluster" {
  cluster_id           = "redis-cluster"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis4.0"

  tags = {
    Name = "RedisCluster"
  }
}

# OpenSearch
resource "aws_opensearch_domain" "search_domain" {
  domain_name           = "search-domain"
  elasticsearch_version = "7.10"

  cluster_config {
    instance_type = "m5.large.elasticsearch"
    instance_count = 1
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }

  tags = {
    Environment = "production"
  }
}

output "vpc_ids" {
  value = [
    aws_vpc.notification_service_vpc.id,
    aws_vpc.input_service_vpc.id,
    aws_vpc.timeline_service_vpc.id,
    aws_vpc.search_service_vpc.id
  ]
}
