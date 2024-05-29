job "frontend" {
	datacenters = ["instaryun"]
  type = "service"

	group "frontend" {
    count = 2

    scaling {
      enabled = true
      min     = 2
      max     = 3
    }

		network {
			mode = "host"
			port "http" {
				to = "8080"
			}
		}

    service {
      name = "frontend"
      tags = [
        "frontend",
        "urlprefix-/website"
      ]
      port = "http"

      check {
        name     = "Frontend HTTP Healthcheck"
        path     = "/"
        type     = "http"
        protocol = "http"
        interval = "10s"
        timeout  = "2s"
      }
    }

		task "frontend" {
			driver = "docker"

			config {
				image = "thedojoseries/frontend:latest"
				ports = ["http"]
			}
		}
	}
}
