resource "nomad_job" "homeassistant" {
  jobspec = file("${path.module}/homeassistant.nomad.hcl")
}
