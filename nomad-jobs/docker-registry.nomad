job "registry" {
    type = "service"

    priority = 80

    # If this task was a regular task, we'd use a constraint here instead & set the weight to -100
    affinity {
        attribute   = "${attr.class}"
        value       = "controller"
        weight      = 100
    }

    group "main" {

        task "registry" {
            driver = "docker"

            config {
                image = "registry:2"
                labels { group = "registry" }
                network_mode = "host"

                port_map {
                    registry = 5000
                }
            }

            resources {
                network {
                    port "registry" {
                        static = 5000
                    }
                }
            }

            service {
                name = "${TASK}"
                tags = [ "infrastructure" ]

                address_mode = "host"
                port = "registry"
                check {
                    type        = "tcp"
                    port        = "registry"
                    interval    = "10s"
                    timeout     = "3s"
                }

            }
        }

        // task "registry-web" {
        //  driver = "docker"
        //
        //  config {
        //      // We're going to have to build our own - the Docker image on the Docker Hub is amd64 only :-/
        //      // See https://github.com/Joxit/docker-registry-ui
        //      image = ""
        //  }
        // }
    }
}
