# Configure the Nomad provider
provider "nomad" {
  address   = var.nomad_address
  secret_id = var.nomad_secret_id
  region    = "global"
}

provider "vault" {
  address = var.vault_address
  token   = var.vault_token
}