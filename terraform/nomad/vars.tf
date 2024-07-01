variable "nomad_address" {
  type    = string
  default = "http://192.168.2.221:4646"
}

variable "vault_address" {
  type    = string
  default = "http://192.168.2.221:8200"
}

variable "base_hostname" {
  type        = string
  description = "Base hostname to serve content from"
  default     = "codecubed.xyz"
}

variable "nomad_secret_id" {
  type        = string
  description = "Secret ID for ACL bootstrapped Nomad"
  sensitive   = true
  default     = ""
}

variable "consul_secret_id" {
  type        = string
  description = "Secret ID for ACL bootstrapped Consul"
  sensitive   = true
  default     = ""
}

variable "vault_token" {
  type        = string
  description = "Vault token"
  sensitive   = true
  default     = ""
}
