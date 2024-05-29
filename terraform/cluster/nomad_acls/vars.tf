variable "nomad_secret_id" {
  type        = string
  description = "Secret ID for ACL bootstrapped Nomad"
  sensitive   = true
  default     = ""
}

variable "nomad_address" {
  type    = string
  default = ""
}
