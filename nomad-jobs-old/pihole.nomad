job "pihole" {
  region = "global"
  datacenters = ["dc1"]

  type = "service"

  group "svc" {
    count = 1
    restart {
      attempts = 5
      delay    = "15s"
    }
    task "app" {
      driver = "docker"
      config {
        image = "pihole/pihole:latest"
        mounts = [
          {
            type     = "bind"
            target   = "/etc/pihole"
            source   = "/mnt/storage/nomad/data/pihole/pihole"
            readonly = false
          },
          {
            type     = "bind"
            target   = "/etc/dnsmasq.d"
            source   = "/mnt/storage/nomad/data/pihole/dnsmasq.d"
            readonly = false
          },
        ]
        port_map {
          dns  = 53
          http = 80
        }
        dns_servers = [
          "127.0.0.1",
          "1.1.1.1",
        ]
      }

      resources {
        cpu    = 100
        memory = 128
        network {
          port "dns" {
            static = 53
          }
          port "http" {}
        }
      }

      service {
        name = "pihole-gui"
        port = "http"
      }
    }
  }
}
