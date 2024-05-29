variable "nomad_address" {
  type    = string
  default = "http://192.168.56.11:4646"
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

variable "consul_address" {
  type    = string
  default = "http://192.168.56.11:8500"
}

variable "consul_datacenter" {
  type    = string
  default = "dc1"
}

variable "consul_secret_id" {
  type        = string
  description = "Secret ID for ACL bootstrapped Consul"
  sensitive   = true
  default     = ""
}
