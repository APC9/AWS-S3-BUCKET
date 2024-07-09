resource "aws_s3_bucket" "AWS-LAB-S3-BUCKET" {
  bucket = var.bucket_name

  tags = {
    Name         = var.bucket_name
    departamento = "Marketing"
    proposito    = "content creation"
  }
}

resource "aws_s3_bucket_ownership_controls" "AWS-S3-OWNERSHIP" {
  bucket = aws_s3_bucket.AWS-LAB-S3-BUCKET.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "AWS-S3-PUBLIC-ACCESS" {
  bucket = aws_s3_bucket.AWS-LAB-S3-BUCKET.id

  # For private access all in = true
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "AWS-S3-BUCKET-ACL" {
  depends_on = [
    aws_s3_bucket_ownership_controls.AWS-S3-OWNERSHIP,
    aws_s3_bucket_public_access_block.AWS-S3-PUBLIC-ACCESS,
  ]

  bucket = aws_s3_bucket.AWS-LAB-S3-BUCKET.id
  acl    = "private" #"public-read"
}

resource "aws_s3_bucket_versioning" "AWS-S3-VERSIONING" {
  bucket = aws_s3_bucket.AWS-LAB-S3-BUCKET.id
  versioning_configuration {
    status = "Enabled"
  }
}

# folder
resource "aws_s3_object" "AWS-S3-FOLDER" {
  for_each = { for file in local.files : file.key => file }

  bucket                 = aws_s3_bucket.AWS-LAB-S3-BUCKET.id
  key                    = "${var.folder_prefix_key.depart}/${each.value.key}" // Nombre de la carpeta: IMPORTANTE COLOCAR "/" al final del nombre
  source                 = each.value.source
  acl                    = "private" #"public-read"
  server_side_encryption = "AES256"  // Server Side Encryption with AWS-Managed Key

  depends_on = [
    aws_s3_bucket.AWS-LAB-S3-BUCKET,
    aws_s3_bucket_ownership_controls.AWS-S3-OWNERSHIP,
    aws_s3_bucket_acl.AWS-S3-BUCKET-ACL,
    aws_s3_bucket_versioning.AWS-S3-VERSIONING
  ]
}

resource "aws_s3_object" "AWS-S3-FOLDER-CONFIDENTIAL" {
  for_each = { for file in local.files : file.key => file }

  bucket                 = aws_s3_bucket.AWS-LAB-S3-BUCKET.id
  key                    = "${var.folder_prefix_key.confi}/${each.value.key}" // Nombre de la carpeta: IMPORTANTE COLOCAR "/" al final del nombre
  source                 = each.value.source
  acl                    = "private" #"public-read"
  server_side_encryption = "AES256"  // Server Side Encryption with AWS-Managed Key

  depends_on = [
    aws_s3_bucket.AWS-LAB-S3-BUCKET,
    aws_s3_bucket_ownership_controls.AWS-S3-OWNERSHIP,
    aws_s3_bucket_acl.AWS-S3-BUCKET-ACL,
    aws_s3_bucket_versioning.AWS-S3-VERSIONING
  ]
}


# create IAM user policy 
resource "aws_iam_policy" "AWS-IAM-POLICY-LIST-BUCKET-S3" {
  name        = "AWS-IAM-POLICY-S3"
  path        = "/"
  description = "My test policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowGroupToSeeBucketListAndAlsoAllowGetBucketLocationRequiredForListBucket",
        "Action" : ["s3:ListAllMyBuckets", "s3:GetBucketLocation"],
        "Effect" : "Allow",
        "Resource" : ["arn:aws:s3:::*"]
      },
      {
        "Sid" : "AllowRootLevelListingOfCompanyBucket",
        "Action" : ["s3:ListBucket"],
        "Effect" : "Allow",
        "Resource" : ["arn:aws:s3:::${var.bucket_name}"],
        "Condition" : {
          "StringEquals" : {
            "s3:prefix" : [""], "s3:delimiter" : ["/"]
          }
        }
      },
      {
        "Sid" : "AllowListBucketIfSpecificPrefixIsIncludedInRequest",
        "Action" : ["s3:ListBucket"],
        "Effect" : "Allow",
        "Resource" : ["arn:aws:s3:::${var.bucket_name}"],
        "Condition" : { "StringLike" : { "s3:prefix" : ["${var.folder_prefix_key.depart}/*"] }
        }
      },
      {
        "Sid" : "AllowUserToReadWriteObjectDataInDepartmentFolder",
        "Action" : ["s3:GetObject", "s3:PutObject"],
        "Effect" : "Allow",
        "Resource" : ["arn:aws:s3:::${var.bucket_name}/${var.folder_prefix_key.depart}/*"]
      }
    ]
  })
}

data "aws_iam_user" "AWS-USER-DEVELOP" {
  user_name = var.iam_user_name
}

resource "aws_iam_user_policy_attachment" "AWS-ATTACH-POLICY-RICHARD" {
  user       = data.aws_iam_user.AWS-USER-DEVELOP.user_name
  policy_arn = aws_iam_policy.AWS-IAM-POLICY-LIST-BUCKET-S3.arn
}

# create Bucket policy S3
resource "aws_s3_bucket_policy" "AWS-S3-BUCKET-POLICY" {
  bucket = aws_s3_bucket.AWS-LAB-S3-BUCKET.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "Policy1561964929358",
    "Statement" : [
      {
        "Sid" : "Stmt1561964454052",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : data.aws_iam_user.AWS-USER-DEVELOP.arn
        },
        "Action" : "s3:*",
        "Resource" : [
          "arn:aws:s3:::${var.bucket_name}",
        ],
        "Condition" : {
          "StringLike" : {
            "s3:prefix" : ["${var.folder_prefix_key.confi}/*"]
          }
        }
      }
    ]
  })
}

#Configuration lifecycle rules
resource "aws_s3_bucket_lifecycle_configuration" "AWS-S3-LIFECYCLE" {
  bucket = aws_s3_bucket.AWS-LAB-S3-BUCKET.id


  rule {
    id = "go-to-infrecuence-access"

    # The Lifecycle rule applies to all objects in the bucket.
    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA" # Mover a Standard-Infrequent Access después de 30 días
    }

    status = "Enabled"
  }

  rule {
    id = "go-to-glacier"

    # The Lifecycle rule applies to all objects in the bucket.
    filter {}

    transition {
      days          = 100
      storage_class = "GLACIER" # Mover a GLACIER Access después de 100 días
    }

    status = "Enabled"
  }

  rule {
    id = "delete-after-one-year"

    # The Lifecycle rule applies to all objects in the bucket.
    filter {}

    expiration {
      days = 365
    }
    status = "Enabled"
  }
}