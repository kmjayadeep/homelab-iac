variable "name" {
  type = string
}

variable "acl" {
  type        = string
  default     = "private"
  description = "ACL of the bucket - private or public"
}

variable "create_user" {
  type        = bool
  default     = false
  description = "Whether to create a user to access this bucket"
}
