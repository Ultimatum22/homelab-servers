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

    vault {
      policies = ["nomad-traefik-policy"]
    }

    volume "acme_volume" {
      type = "host"
      source = "acme_volume"
      read_only = false
    }

    network {
      mode = "bridge"

      port "http" {
        static = 80
        to     = 80
      }

      port "https" {
        static = 443
        to     = 443
      }

      port "metrics" {
        static = 8899
        to     = 8899
      }
    }

    service {
      name = "traefik-ingress"
      port = "http"
      task = "traefik"

      tags = [
        "traefik",
        "traefik.enable=true",
        "traefik.http.routers.dashboard.rule=Host(`traefik.dashboards.codecubed.xyz`)",
        "traefik.http.routers.dashboard.service=api@internal",
        "traefik.http.routers.dashboard.entrypoints=https",
        // "traefik.http.routers.nomad.rule=Host(`nomad.dashboards.codecubed.xyz`)",
        // "traefik.http.routers.nomad.service=nomad-ui@consul",
        // "traefik.http.routers.nomad.entrypoints=https",
	      // "traefik.http.routers.consul.rule=Host(`consul.dashboards.codecubed.xyz`)",
        // "traefik.http.routers.consul.service=consul-ui@consul",
        // "traefik.http.routers.consul.entrypoints=https",

      ]

      check {
        name     = "alive"
        type     = "tcp"
        port     = "http"
        interval = "10s"
        timeout  = "2s"
      }

      connect {
        native = true
      }
    }

    task "traefik" {
      driver = "docker"

      volume_mount {
        volume = "acme_volume"
        destination = "/data"
      }

      config {
        image = "traefik:v3.0"
        
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
            [entryPoints.http.http.redirections.entryPoint]
              to = "https"
              scheme = "https"
              permanent = false  # Change this to false to avoid permanent redirection

          [entryPoints.https]
            address = ":443"
            [entryPoints.https.http]
              middlewares = ["hsts@file"]
              [entryPoints.https.http.tls]

          [entryPoints.metrics]
            address = ":8899"

        [providers]
          [providers.file]
            directory = "/local/conf/dynamic"

          [providers.consulCatalog]
            connectAware = true
            exposedByDefault = false
            connectByDefault = false
            serviceName = "traefik-ingress"
            cache = true

        [metrics]
          [metrics.prometheus]
            entryPoint = "metrics"

        [log]
          format = "json"
          level = "DEBUG"

        [accessLog]
          format = "json"

        [api]
          dashboard = true
          insecure = true
          debug = true
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

      service {
        name = "traefik-metrics"
        port = "metrics"

        tags = [
          "traefik-metrics",
          "prometheus",
        ]
      }
    }
  }
}
