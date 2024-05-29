# # resource "nomad_job" "loki" {
# #   jobspec = file("${path.module}/loki.nomad.hcl")
# #   detach = false
# # }

# # resource "nomad_job" "promtail" {
# #   jobspec = file("${path.module}/promtail.nomad.hcl")
# #   detach = false
# # }

# resource "nomad_job" "grafana" {
#   jobspec = file("${path.module}/grafana.nomad.hcl")

#   # depends_on = [
#   #   nomad_job.promtail,
#   #   nomad_job.loki
#   # ]
# }



resource "nomad_job" "victoriametrics" {
  jobspec = file("${path.module}/victoriametrics.nomad.hcl")
  detach = false
}

resource "nomad_job" "vmagent" {
  jobspec = file("${path.module}/vmagent.nomad.hcl")

  depends_on = [
    nomad_job.victoriametrics
  ]
}

resource "nomad_job" "grafana" {
  jobspec = file("${path.module}/grafana.nomad.hcl")

  depends_on = [
    nomad_job.victoriametrics
  ]
}
