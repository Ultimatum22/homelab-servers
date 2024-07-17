job "http-echo-gui" {

  type = "service"

  group "echo" {

    network {
        port "heartbeat" {
            static = 8080
        }
    }

    count = 1

    task "server" {

      driver = "docker"

      config {
        image = "hashicorp/http-echo:latest"
        ports = ["heartbeat"]
        args  = [
          "-listen", ":${NOMAD_PORT_heartbeat}",
          "-text", "${attr.os.name}: server running on ${NOMAD_IP_heartbeat} with port ${NOMAD_PORT_heartbeat}",
        ]
      }

      service {

        name = "http-echo"
        port = "heartbeat"

        tags = [
          "heartbeat",
          "urlprefix-/http-echo",
        ]

        check {
          type     = "http"
          path     = "/health"
          interval = "2s"
          timeout  = "2s"
        }
      }
    }
  }
}
