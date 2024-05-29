job "fabio" {

  datacenters = ["dc1"]

  type = "system"

  update {
    max_parallel = 1
    stagger      = "30s"

    # Enable automatically reverting to the last stable job on a failed
    # deployment.
    auto_revert = true
  }

  group "fabio" {
    network {
      port "lb" {
        static = 9999
      }
      port "ui" {
        static = 9998
      }
    }
    task "fabio" {
      driver = "docker"

      config {
        image = "fabiolb/fabio"
        network_mode = "host"
        ports = ["lb","ui"]
      }

      resources {
        cpu    = 200
        memory = 128
      }
    }
  }
}
