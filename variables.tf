# Input variable definitions

variable "domain" {
  description = "Domain (must already have a vaild ACM certificate in the US East (N. Virginia) Region)"
  type        = string
}

variable "allowlist_ip" {
  description = "IPv4 CIDR ranges allowed to access the distribution"
  type        = list(string)
  default     = []
}
