# https://learn.hashicorp.com/nomad/load-balancing/fabio
job "nginx" {
  datacenters = ["dc1"]
  type = "service"

  group "http" {
    count = 3

    task "nginx" {

        driver = "docker"

        config {
            image = "nginx"
        }

        resources {
            cpu = 500
            memory = 256
        }
    }
  }
}
