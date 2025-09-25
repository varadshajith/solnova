variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS named profile (optional)"
  type        = string
  default     = null
}

variable "project" {
  description = "Project name prefix"
  type        = string
  default     = "solnova"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
