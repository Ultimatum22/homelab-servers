# Configure the Nomad provider
provider "nomad" {
  address   = var.nomad_address
  secret_id = var.nomad_secret_id
  region    = "global"
}

provider "vault" {
  address = "http://127.0.0.1:8200"
  token   = "your-vault-token"
}