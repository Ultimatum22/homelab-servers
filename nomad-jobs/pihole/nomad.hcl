job "pihole" {
  region      = "[[ .nomad.region ]]"
  datacenters = ["[[ .nomad.datacenter ]]"]
  type        = "system"
  priority    = 100

  group "pihole" {
    network {
      port "dns" { static = 53, to = 53 }
      port "http" { static = 7254, to = 80 }
    }

    update {
      max_parallel = 1
      stagger      = "1m"
      min_healthy_time = "30s"
      auto_revert = true
    }

    task "server" {
      driver = "docker"
      config {
        image = "pihole/pihole:2024.07.0"
        ports = [
          "dns",
          "http",
        ]
        volumes = [
          "pihole_etc:/etc/pihole/",
          "pihole_dnsmasqd:/etc/dnsmasq.d/",
        ]
        cap_add = ["net_admin", "setfcap"]
        network_mode = "bridge"  # Use bridge network mode for Docker
      }
      env = {
        "WEBPASSWORD" = "your_secure_password"
      }

      template {
        data = <<-EOF
          server=1.1.1.1
          server=1.0.0.1
        EOF

        destination = "/etc/dnsmasq.d/dns-servers.conf"
      }

      service {
        name = "pihole-gui"
        port = "http"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.api.rule=Host(`pihole.codecubed.xyz`)",
          "traefik.http.routers.api.service=api@internal",
        ]
      }
    }
  }
}
