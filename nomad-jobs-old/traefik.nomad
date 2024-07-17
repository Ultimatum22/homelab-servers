job "traefik" {
  datacenters = ["dc1"]
  type        = "system"

  update {
    max_parallel = 1
    stagger      = "1m"

    # Enable automatically reverting to the last stable job on a failed
    # deployment.
    auto_revert = true
  }

  group "traefik" {
    network {
      port "web" {
        static = 80
      }
      port "websecure" {
        static = 443
      }
      port "metrics" {
        static = 8082
      }
    }

    service {
      name = "traefik"
      port = "websecure"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.api.rule=Host(`traefik.codecubed.xyz`)",
        "traefik.http.routers.api.service=api@internal",
      ]

      check {
        type     = "http"
        path     = "/ping"
        port     = "web"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "traefik" {
      driver = "docker"

      config {
        image        = "traefik:v3.0"
        ports        = ["web", "websecure"]
        network_mode = "host"

        volumes = [
          "local/traefik.yaml:/etc/traefik/traefik.yaml",
        ]
      }

      template {
        data = <<EOF
entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"
  metrics:
    address: ":8082"

api:
  dashboard: true
  insecure: true

ping:
  entryPoint: "web"

accessLog: {}

tracing: {}

log:
  level: "DEBUG"

metrics:
 prometheus:
   entryPoint: metrics

serversTransport:
  insecureSkipVerify: true

providers:
  consulCatalog:
    cache: true
    prefix: "traefik"
    exposedByDefault: false
    endpoint:
      address: "127.0.0.1:8500"
      scheme: "http"
    connectAware: true
EOF

        destination = "local/traefik.yaml"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
