resource "aws_s3_bucket" "logs_bucket" {
  bucket        = "${lower(var.name)}-logs"
  force_destroy = true

  tags = {
    Name = "${lower(var.name)}-logs"
  }
}

resource "aws_s3_bucket" "blobs_bucket" {
  bucket        = "${lower(var.name)}-blobs"
  force_destroy = true

  tags = {
    Name = "${lower(var.name)}-blobs"
  }
}

resource "aws_s3_bucket" "backups_bucket" {
  bucket        = "${lower(var.name)}-backups"
  force_destroy = true

  tags = {
    Name = "${lower(var.name)}-backups"
  }
}

data "aws_iam_policy_document" "s3_bucket_access" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:ListBucketMultipartUploads"
    ]

    resources = [
      "arn:aws:s3:::${lower(var.name)}-backups",
      "arn:aws:s3:::${lower(var.name)}-blobs",
      "arn:aws:s3:::${lower(var.name)}-logs"
    ]
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload"
    ]

    resources = [
      "arn:aws:s3:::${lower(var.name)}-backups/*",
      "arn:aws:s3:::${lower(var.name)}-blobs/*",
      "arn:aws:s3:::${lower(var.name)}-logs/*"
    ]
  }
}

resource "aws_iam_policy" "s3_bucket_access" {
  name   = "${var.name}-nodes-s3-bucket-access"
  policy = data.aws_iam_policy_document.s3_bucket_access.json
}
