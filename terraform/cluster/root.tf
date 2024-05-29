# Can't run this as part of root and as a submodule because of tf state
module "nomad_acls" {
  source = "./nomad_acls"

  nomad_address   = var.nomad_address
  nomad_secret_id = var.nomad_secret_id
}

module "consul_acls" {
  source = "./consul_acls"
}

terraform {
  required_version = ">=1.7.2"
}
