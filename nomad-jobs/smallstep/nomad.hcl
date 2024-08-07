job "smallstep" {
  type        = "service"

  group "smallstep" {

    network {
      mode = "bridge"

      port "envoy_metrics" { to = 9102 }
    }

    service {
      name = "smallstep"

      port = 9443

      # WTF??? health check causes Envoy bootstrap error!
//       check {
//         type     = "http"
// #        protocol = "https"
// #        tls_skip_verify = true
//         path     = "/health"
//         interval = "5s"
//         timeout  = "2s"
//         expose   = true # required for Connect
//       }

      meta {
        envoy_metrics_port = "${NOMAD_HOST_PORT_envoy_metrics}" # make envoy metrics port available in Consul
      }
      connect {
        sidecar_service { 
          proxy {
            config {
              envoy_prometheus_bind_addr = "0.0.0.0:9102"
            }
          }
        }

        sidecar_task {
          resources {
            cpu    = 50
            memory = 48
          }
        }
      }
    }

    task "server" {
      driver = "docker"

      config {
        image = "smallstep/step-ca:latest"
      }

      env {
        TZ = "Europe/Berlin"
      }

      resources {
        memory = 300
        cpu    = 50
      }

      volume_mount {
        volume      = "smallstep"
        destination = "/home/step"
      }
    }

    volume "smallstep" {
      type            = "csi"
      source          = "smallstep"
      access_mode     = "single-node-writer"
      attachment_mode = "file-system"
    }
  }
}