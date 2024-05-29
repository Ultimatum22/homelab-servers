job "scrutiny" {
  
  type        = "service"

  group "scrutiny" {
    count = 1

    network {
      port "http" {
        to = 8080
      }
    }

    task "scrutiny" {
      driver = "docker"

      config {
        image        = "ghcr.io/analogj/scrutiny:v0.7.3-web"
        ports        = ["http"]
      }

      resources {
        cpu    = 500 # Adjust according to your needs
        memory = 512 # Adjust according to your needs
      }

      service {
        name = "scrutiny"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.scrutiny.rule=Host(`disks.codecubed.xyz`) && PathPrefix(`/scrutiny`)",
          "traefik.http.services.scrutiny.loadbalancer.server.port=8080`",
        ]
        port = "http"
      }
    }
  }
}
