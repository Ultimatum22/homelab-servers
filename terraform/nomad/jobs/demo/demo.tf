resource "nomad_job" "demo" {
  jobspec = file("${path.module}/demo.nomad.hcl")
}
