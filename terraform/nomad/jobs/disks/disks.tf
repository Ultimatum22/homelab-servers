resource "nomad_job" "disks" {
  jobspec = file("${path.module}/disks.nomad.hcl")
}
