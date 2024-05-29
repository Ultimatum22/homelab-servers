job "homeassistant" {
  type = "service"

  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "6m"
    progress_deadline = "10m"
    auto_revert = false
    canary = 0
  }

  migrate {
    max_parallel = 1
    health_check = "checks"
    min_healthy_time = "15s"
    healthy_deadline = "10m"
  }

  group "homeassistant" {
    count = 1

    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }

    task "homeassistant_core" {
      driver = "docker"

      config {
        hostname = "hostname"
        force_pull = true
        image = "homeassistant/home-assistant:2024.2.3"
        network_mode = "host"
        // privileged = true
        // volumes = [
        //     "/nfs/home_assistant/config:/config",
        //     "/etc/localtime:/etc/localtime:ro"
        // ]
        port_map {
          homeassistant_core = 8123
        }
      }
      resources {
        cpu    = 800 # 500 MHz
        memory = 512 # 512 MB

        network {
          mbits = 300
          port "homeassistant_core" { static = 8123 }
        }
      }

      service {
        name = "homeassistant"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.homeassistant.rule=Host(`ha.codecubed.xyz`)",
          "traefik.http.routers.homeassistant.entrypoints=https",
        ]
        port = "homeassistant_core"

        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
