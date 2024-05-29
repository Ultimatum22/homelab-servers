job "victoriametrics" {

  type        = "service"

  group "victoriametrics" {
    count = 1

    volume "victoriametrics" {
      type      = "host"
      read_only = false
      source    = "victoriametrics"
    }

    network {
      mode = "bridge"

      port "vicky-http" {
        to = 8428
      }
    }

    task "victoriametrics" {
      driver = "docker"

      service {
        name     = "vicky-web"
        provider = "nomad"
        tags     = [
          "victoriametrics",
          "web",
          "time-series",
          "urlprefix-/victoriametrics strip=/victoriametrics",
          "traefik.enable=true",
          "traefik.http.routers.victoriametrics.rule=PathPrefix(`/victoriametrics`)",
          "traefik.http.middlewares.victoriametrics.stripprefix.prefixes=/victoriametrics"
        ]
        port     = "vicky-http"
      }

      volume_mount {
        volume      = "victoriametrics"
        destination = "/storage"
        read_only   = false
      }

      config {
        image = "victoriametrics/victoria-metrics:v1.93.12"
        ports = ["vicky-http"]
        args = [
          "--storageDataPath=/storage",
          "--retentionPeriod=1",
          "--httpListenAddr=:8428"
        ]
      }

      resources {
        cpu    = 256
        memory = 300
      }
    }
  }

}
