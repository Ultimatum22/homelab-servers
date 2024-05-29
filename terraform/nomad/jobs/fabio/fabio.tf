resource "nomad_job" "fabio" {
  jobspec = file("${path.module}/fabio.nomad.hcl")
}
