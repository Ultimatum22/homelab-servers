resource "nomad_job" "registry" {
  jobspec = file("${path.module}/registry.nomad.hcl")
}
