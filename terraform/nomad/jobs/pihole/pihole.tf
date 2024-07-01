resource "nomad_job" "pihole" {
  jobspec = file("${path.module}/pihole.nomad.hcl")
}
