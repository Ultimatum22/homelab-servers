resource "consul_acl_policy" "dns-request" {
  name        = "dns-request-policy"
  datacenters = ["dc1"]
  rules   = file("${path.module}/dns-request-policy.hcl")
}
