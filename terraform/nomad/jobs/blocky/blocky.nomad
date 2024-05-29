variable "config_data" {
  type = string
  description = "Plain text config file for blocky"
}

job "blocky" {
  datacenters = ["dc1"]
  type = "system"
  priority = 100

  update {
    max_parallel = 1
    stagger      = "1m"

    auto_revert = true
  }

  group "blocky" {

    network {
      mode = "bridge"

      port "dns" {
        static = "53"
      }

      port "api" {
        to = "4000"
      }

      dns {
        # Set expclicit DNS servers because tasks, by default, use this task
        servers = ["1.1.1.1", "1.0.0.1"]
      }
    }

    service {
      name = "blocky-dns"
      provider = "nomad"
      port = "dns"
    }

    service {
      name = "blocky-api"
      provider = "nomad"
      port = "api"

      tags = [
        "prometheus.scrape",
        "traefik.enable=true",
        "traefik.http.routers.blocky-api.entryPoints=websecure",
      ]

      check {
        name     = "api-health"
        port     = "api"
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "3s"
      }
    }

    task "blocky" {
      driver = "docker"

      config {
        image = "spx01/blocky:v0.23"
        args = ["-c", "$${NOMAD_TASK_DIR}/config.yml"]
        ports = ["dns", "api"]
      }

      resources {
        cpu = 50
        memory = 50
        memory_max = 100
      }

      template {
        data = var.config_data
        destination = "$${NOMAD_TASK_DIR}/config.yml"
        splay = "1m"

        wait {
          min = "10s"
          max = "20s"
        }
      }

      template {
        data = <<EOF
{{ range nomadServices }}
{{ range nomadService 1 (env "NOMAD_ALLOC_ID") .Name -}}
{{ .Address }} {{ .Name }}.nomad
{{- end }}
{{- end }}
        EOF
        destination = "$${NOMAD_TASK_DIR}/nomad.hosts"
        change_mode = "noop"

        wait {
          min = "10s"
          max = "20s"
        }
      }
    }
  }
}
