job "haproxy" {
  type = "service"

  group "haproxy" {
    count = 3

    task "haproxy" {
      driver = "docker"

      config {
        image = "haproxy:latest"
        ports = ["dns"]
      }

      resources {
        cpu    = 500
        memory = 256
      }

      service {
        name = "haproxy"
        port = "dns"
        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }

    network {
      port "dns" {
        to = "53"
      }
    }

    volume "local" {
      type   = "host"
      source = "/etc/haproxy/haproxy.cfg"
      read_only = true
    }
  }
}
