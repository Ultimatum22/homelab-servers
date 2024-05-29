# Configure the Nomad provider
provider "nomad" {
  address   = var.nomad_address
  secret_id = var.nomad_secret_id
  region    = "global"
}

provider "consul" {
  address    = var.consul_address
  datacenter = var.consul_datacenter
  token      = var.consul_secret_id
}
