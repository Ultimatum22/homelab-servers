resource "nomad_acl_policy" "anon_policy" {
  name        = "anonymous"
  description = "Anon RO"
  rules_hcl   = file("${path.module}/nomad-anon-policy.hcl")
}

resource "nomad_acl_policy" "admin" {
  name        = "admin"
  description = "Admin RW for admins"
  rules_hcl   = file("${path.module}/nomad-admin-policy.hcl")
}

# TODO: (security) Limit this scope
resource "nomad_acl_policy" "deploy" {
  name        = "deploy"
  description = "Write for job deployments"
  rules_hcl   = file("${path.module}/nomad-deploy-policy.hcl")
}
