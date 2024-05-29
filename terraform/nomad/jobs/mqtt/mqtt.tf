resource "nomad_job" "mqtt" {
  jobspec = file("${path.module}/mqtt.nomad.hcl")
}
