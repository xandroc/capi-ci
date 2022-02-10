# INPUTS

variable "env_name" {
}

variable "aws_access_key" {
}

variable "aws_secret_key" {
}

variable "cdn_key_pair_id" {
}

variable "cdn_private_key" {
}

variable "aws_region" {
  default = "us-west-1"
}

# Declare outputs as empty variables here

variable "cc_storage_region" {
}

variable "cc_s3_buildpack_bucket_name" {
}

variable "cc_s3_access_key" {
}

variable "cc_s3_secret_key" {
}

variable "cc_s3_droplet_bucket_name" {
}

variable "cc_cdn_droplet_uri" {
}

variable "cc_cdn_droplet_private_key" {
}

variable "cc_cdn_droplet_key_pair_id" {
}

variable "cc_s3_package_bucket_name" {
}

variable "cc_s3_resource_pool_bucket_name" {
}

variable "cc_cdn_resource_pool_uri" {
}

variable "cc_cdn_resource_pool_private_key" {
}

variable "cc_cdn_resource_pool_key_pair_id" {
}

# TASK

# Create four buckets:
#   - two buckets under cloudfront
#   - two direct s3 buckets

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.aws_region
}

data "aws_caller_identity" "current" {
}

resource "aws_s3_bucket" "resource_pool" {
  bucket = "${var.env_name}-cc-resource-pool"

  tags = {
    Name = var.env_name
  }
}

resource "aws_s3_bucket_acl" "resource_pool" {
  bucket = aws_s3_bucket.resource_pool.id
  acl    = "private"
}

resource "aws_s3_bucket" "droplets" {
  bucket = "${var.env_name}-cc-droplets"

  tags = {
    Name = var.env_name
  }
}

resource "aws_s3_bucket_acl" "droplets" {
  bucket = aws_s3_bucket.droplets.id
  acl    = "private"
}

resource "aws_s3_bucket" "packages" {
  bucket = "${var.env_name}-cc-packages"

  tags = {
    Name = var.env_name
  }
}

resource "aws_s3_bucket_acl" "packages" {
  bucket = aws_s3_bucket.packages.id
  acl    = "private"
}

resource "aws_s3_bucket" "buildpacks" {
  bucket = "${var.env_name}-cc-buildpacks"

  tags = {
    Name = var.env_name
  }
}

resource "aws_s3_bucket_acl" "buildpacks" {
  bucket = aws_s3_bucket.buildpacks.id
  acl    = "private"
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Used to allow CloudFront to GET from private S3 bucket"
}

data "aws_iam_policy_document" "resource_pool_policy" {
  statement {
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.resource_pool.arn}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }

  statement {
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.resource_pool.arn,
      "${aws_s3_bucket.resource_pool.arn}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.arn]
    }
  }
}

data "aws_iam_policy_document" "droplets_policy" {
  statement {
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.droplets.arn}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }

  statement {
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.droplets.arn,
      "${aws_s3_bucket.droplets.arn}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.arn]
    }
  }
}

data "aws_iam_policy_document" "packages_policy" {
  statement {
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.packages.arn,
      "${aws_s3_bucket.packages.arn}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.arn]
    }
  }
}

data "aws_iam_policy_document" "buildpacks_policy" {
  statement {
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.buildpacks.arn,
      "${aws_s3_bucket.buildpacks.arn}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "resource_pool" {
  bucket = aws_s3_bucket.resource_pool.id
  policy = data.aws_iam_policy_document.resource_pool_policy.json
}

resource "aws_s3_bucket_policy" "droplets" {
  bucket = aws_s3_bucket.droplets.id
  policy = data.aws_iam_policy_document.droplets_policy.json
}

resource "aws_s3_bucket_policy" "buildpacks" {
  bucket = aws_s3_bucket.buildpacks.id
  policy = data.aws_iam_policy_document.buildpacks_policy.json
}

resource "aws_s3_bucket_policy" "packages" {
  bucket = aws_s3_bucket.packages.id
  policy = data.aws_iam_policy_document.packages_policy.json
}

# Create CloudFront in front of bucket

resource "aws_cloudfront_distribution" "resource_pool_distribution" {
  origin {
    domain_name = aws_s3_bucket.resource_pool.bucket_domain_name
    origin_id   = "${var.env_name}-resource-pool"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled = true

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.env_name}-resource-pool"

    trusted_signers = ["self"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "https-only"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = var.env_name
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_cloudfront_distribution" "droplets_distribution" {
  origin {
    domain_name = aws_s3_bucket.droplets.bucket_domain_name
    origin_id   = "${var.env_name}-droplets"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled = true

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.env_name}-droplets"

    trusted_signers = ["self"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "https-only"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = var.env_name
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# OUTPUTS

output "cc_storage_region" {
  value = var.aws_region
}

output "cc_s3_buildpack_bucket_name" {
  value = aws_s3_bucket.buildpacks.id
}

output "cc_s3_access_key" {
  value     = var.aws_access_key
  sensitive = true
}

output "cc_s3_secret_key" {
  value     = var.aws_secret_key
  sensitive = true
}

output "cc_s3_droplet_bucket_name" {
  value = aws_s3_bucket.droplets.id
}

output "cc_cdn_droplet_uri" {
  value = "https://${aws_cloudfront_distribution.droplets_distribution.domain_name}"
}

output "cc_cdn_droplet_private_key" {
  value     = var.cdn_private_key
  sensitive = true
}

output "cc_cdn_droplet_key_pair_id" {
  value     = var.cdn_key_pair_id
  sensitive = true
}

output "cc_s3_package_bucket_name" {
  value = aws_s3_bucket.packages.id
}

output "cc_s3_resource_pool_bucket_name" {
  value = aws_s3_bucket.resource_pool.id
}

output "cc_cdn_resource_pool_uri" {
  value = "https://${aws_cloudfront_distribution.resource_pool_distribution.domain_name}"
}

output "cc_cdn_resource_pool_private_key" {
  value     = var.cdn_private_key
  sensitive = true
}

output "cc_cdn_resource_pool_key_pair_id" {
  value     = var.cdn_key_pair_id
  sensitive = true
}

