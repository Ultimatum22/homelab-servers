resource "nomad_job" "traefik" {
  jobspec = file("${path.module}/traefik.nomad.hcl")
}
