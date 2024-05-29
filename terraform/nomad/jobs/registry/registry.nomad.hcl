job "traefik" {
  type = "system"

  update {
    max_parallel = 1
    stagger      = "30s"
    auto_revert = true
  }

  group "traefik" {

    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    network {
      mode = "bridge"

      port "http" {
        static = 80
        to     = 80
      }

      port "api" {
        static = 81
        to     = 81
      }

      port "https" {
        static = 443
        to = 443
      }

      port "health" {
        to = 8082
      }
    }

    service {
      name = "traefik-ingress"
      port = "http"
      task = "traefik"

      tags = [
       "traefik",
       "traefik.enable=true",
       "traefik.http.routers.dashboard.rule=Host(`traefik.codecubed.xyz`)",
       "traefik.http.routers.dashboard.service=api@internal",
       "traefik.http.routers.dashboard.entrypoints=http",
      ]

      check {
        type = "http"
        path = "/ping"
        port = "health"
        interval = "10s"
        timeout = "2s"
      }

      connect {
        native = true
      }
    }

    task "traefik" {
      driver = "docker"
      config {
        image = "traefik:v2.6.0"
        args = [
          "--configFile=/local/conf/traefik.toml",
        ]
      }

      template {
        destination = "${NOMAD_TASK_DIR}/conf/traefik.toml"
        env = false
        change_mode = "restart"
        splay = "1m"
        data = <<-EOH
          [entryPoints.http]
            address = ":80"
          [entryPoints.http.forwardedHeaders]
            trustedIPs = ["136.144.151.253","136.144.151.254","136.144.151.255","89.41.168.61","89.41.168.62","89.41.168.63"]
          [entryPoints.http.http]
            [entryPoints.http.http.redirections]
              [entryPoints.http.http.redirections.entryPoint]
                to = "https"
                scheme = "https"
                permanent = true
          [entryPoints.traefik]
            address = ":81"
          [entryPoints.https]
            address = ":443"
            [entryPoints.https.http]
              middlewares = ["hsts@file"]
              [entryPoints.https.http.tls]
          [entryPoints.ping]
            address = ":8082"
        [providers]
          [providers.file]
            directory = "/local/conf/dynamic"
          [providers.consulCatalog]
            connectAware = true
            exposedByDefault = false
            connectByDefault = false
            serviceName = "traefik-ingress"
            cache = true
        # /ping endpoint
        [ping]
          entryPoint = "ping"
        [log]
          format = "json"
          level = "DEBUG"
        [accessLog]
          format = "json"
        [api]
          dashboard = true
          insecure = true
        EOH
      }

      template {
        destination = "${NOMAD_TASK_DIR}/conf/dynamic/traefik.toml"
        env = false
        change_mode = "noop"
        splay = "1m"
        data = <<-EOH
        [http]
          [http.middlewares]
            [http.middlewares.hsts.headers]
              stsSeconds=63072000
              stsIncludeSubdomains=true
              stsPreload=true
        EOH
      }
    }
  }
}
