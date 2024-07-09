# Goblal tags
variable "tags" {
  description = "tags del proyecto"
  type        = map(string)
}

# AWS Region
variable "region" {
  description = "Region in which AWS resources to be created"
  type        = string
  default     = ""
}

# Environment Variable
variable "enviroment" {
  description = "Environment Variable used as a prefix"
  type        = string
  default     = ""
}

# Business Division
variable "owners" {
  description = "Organization this Infraestructure belongs"
  type        = string
  default     = ""
}


# Environment Bucket S3 

variable "bucket_name" {
  description = "Bucket name"
  type        = string
}

variable "iam_user_name" {
  description = "iam user name"
  type        = string
}

variable "folder_prefix_key" {
  description = "prefixs key folders name"
  type        = map(string)
}