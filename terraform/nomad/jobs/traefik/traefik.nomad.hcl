job "traefik" {
  datacenters = ["dc1"]

  group "traefik" {
    count = 1

    task "traefik" {
      driver = "docker"

      config {
        image = "traefik:v2.9"
        ports = ["http", "https"]

        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml",
          "local/certs:/certs"
        ]
      }

      env {
        VAULT_ADDR = "http://192.168.56.11:8200"
        VAULT_TOKEN = "hvs.dBzNAkLZ3DrFPt96rGn1L031"
      }

      resources {
        cpu    = 500
        memory = 512
      }

      service {
        name = "traefik"
        tags = ["traefik", "http"]
        port = "http"
      }

      service {
        name = "traefik-https"
        tags = ["traefik", "https"]
        port = "https"
      }

      template {
        data = <<EOH
        # traefik.toml configuration file

        [entryPoints]
          [entryPoints.http]
            address = ":80"
          [entryPoints.https]
            address = ":443"

        [certificatesResolvers.myresolver.acme]
          email = "your-email@example.com"
          storage = "acme.json"
          [certificatesResolvers.myresolver.acme.httpChallenge]
            entryPoint = "http"

        [providers.file]
          directory = "/etc/traefik/dynamic/"
        EOH
        destination = "local/traefik.toml"
      }

      template {
        data = <<EOH
        # dynamic.toml configuration file

        [[tls.certificates]]
          certFile = "/certs/traefik.crt"
          keyFile = "/certs/traefik.key"
        EOH
        destination = "local/dynamic.toml"
      }

      template {
        data = <<EOH
        {{ with secret "pki/issue/traefik" "common_name=traefik.example.com" }}
        {{ .Data.certificate }}{{ end }}
        EOH
        destination = "local/certs/traefik.crt"
        change_mode = "restart"
      }

      template {
        data = <<EOH
        {{ with secret "pki/issue/traefik" "common_name=traefik.example.com" }}
        {{ .Data.private_key }}{{ end }}
        EOH
        destination = "local/certs/traefik.key"
        change_mode = "restart"
      }
    }

    network {
      port "http" {
        static = 8080
      }

      port "https" {
        static = 8443
      }
    }
  }
}
