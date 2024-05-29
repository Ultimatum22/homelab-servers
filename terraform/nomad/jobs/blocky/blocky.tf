locals {
  config_data = file("${path.module}/config.yml")
}

resource "nomad_job" "blocky" {
  hcl2 {
    vars = {
      "config_data" = local.config_data,
    }
  }

  jobspec = templatefile("${path.module}/blocky.nomad", {

  })
}
