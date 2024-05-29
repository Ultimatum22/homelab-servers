resource "nomad_acl_role" "admin" {
  name        = "admin"
  description = "Nomad administrators"

  policy {
    name = nomad_acl_policy.admin.name
  }
}

resource "nomad_acl_role" "deploy" {
  name        = "deploy"
  description = "Authorized to conduct deployments and view logs"

  policy {
    name = nomad_acl_policy.deploy.name
  }
}
