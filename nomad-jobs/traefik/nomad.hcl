job "traefik" {
  type        = "service"

  # Traefik instance for the home (internal) network
  group "traefik-home" {

    network {
      mode = "bridge"

      port "metrics" { to = 8080 } # Prometheus metrics via API port

      port "envoy_metrics_api" { to = 9102 }
      port "envoy_metrics_home_https" { to = 9103 }
      port "envoy_metrics_cloudflare" { to = 9104 }
      port "envoy_metrics_home_http" { to = 9105 }
    }

    ephemeral_disk {
      # Used to store the JSON cert stores, Nomad will try to preserve the disk between job updates.
      # Preserving the JSON store prevents Let's Encrypt from banning you for a certain time if you request too many certs 
      #  in a short timeframe due to Traefik re-deployments
      size    = 300 # MB
      migrate = true
    }

    service {
      name = "traefik-home-api"

      port = 8080

      check {
        type     = "http"
        path     = "/ping"
        interval = "5s"
        timeout  = "2s"
        expose   = true # required for Connect
      }

      meta {
        envoy_metrics_port = "${NOMAD_HOST_PORT_envoy_metrics_api}" # make envoy metrics port available in Consul
        metrics_port = "${NOMAD_HOST_PORT_metrics}"
      }
      connect {
        sidecar_service { 
          proxy {
            config {
              envoy_prometheus_bind_addr = "0.0.0.0:9102"
            }
            upstreams {
              destination_name = "smallstep"
              local_bind_port  = 9443
            }
          }
        }

        sidecar_task {
          resources {
            cpu    = 50
            memory = 48
          }
        }
      }

      tags = [
        "traefik.enable=true",
        "traefik.consulcatalog.connect=true",
        "traefik.http.routers.traefik.rule=Host(`lab.home`) || Host(`traefik.lab.home`)",
        "traefik.http.routers.traefik.service=api@internal",
        "traefik.http.routers.traefik.entrypoints=websecure"
      ]
    }

    service {
      name = "traefik-home-http"

      port = 80
      tags = ["home"]

      meta {
        envoy_metrics_port = "${NOMAD_HOST_PORT_envoy_metrics_home_http}" # make envoy metrics port available in Consul
      }
      connect {
        sidecar_service {
          proxy {
            config {
              envoy_prometheus_bind_addr = "0.0.0.0:9105"
            }
          }
        }

        sidecar_task {
          resources {
            cpu    = 50
            memory = 48
          }
        }
      }
    }

    service {
      name = "traefik-home-https"

      port = 443
      tags = ["home"]

      meta {
        envoy_metrics_port = "${NOMAD_HOST_PORT_envoy_metrics_home_https}" # make envoy metrics port available in Consul
      }
      connect {
        sidecar_service {
          proxy {
            config {
              envoy_prometheus_bind_addr = "0.0.0.0:9103"
            }
          }
        }

        sidecar_task {
          resources {
            cpu    = 50
            memory = 48
          }
        }
      }
    }

    # NOTE: If you are intrested in routing incomming traffic from your router, please have a look at earlier versions.
    #  I have changed the setup to Cloudflare tunnels, but you can find the original setup in the projects traefik and consul-ingress
    task "server" {

      driver = "docker"

      config {
        image = "traefik:latest"

        args = [ "--configFile=/local/traefik.yaml" ]
      }

      env {
        LEGO_CA_SYSTEM_CERT_POOL = true
        LEGO_CA_CERTIFICATES = "${NOMAD_SECRETS_DIR}/intermediate_ca.crt"
      }

      template {
        destination = "local/traefik.yaml"
        data        = <<EOH
# static configuration 

providers:
  file:
    directory: "/local/conf"
    watch: false
  consulcatalog:
    prefix: "traefik"
    watch: true # use watch instead of polling
    connectaware: true
    exposedByDefault: false
    servicename: "traefik-home-api" # connects Traefik to the Consul service
    endpoint:
      address: "http://consul.service.consul:8500"

certificatesResolvers:
  home:
    acme:
      caServer: "https://localhost:9443/acme/home/directory" # bound via Consul Connect
      email: "{{- with nomadVar "nomad/jobs/traefik" }}{{- .ca_email }}{{- end }}"
      storage: "{{ env "NOMAD_ALLOC_DIR" }}/data/home.json"
      tlsChallenge: {}

entryPoints:
  # internal
  web:
    address: :80
    http:
      redirections: # global redirct to https
        entrypoint:
          to: websecure
          scheme: https
  websecure:
    address: :443
    http:
      tls: 
        options: strict_tls@file
        certResolver: home
  # Traefik API
  traefik:
    address: :8080

serversTransport:
  insecureSkipVerify: true # trust internal TLS connection without cert validation
  rootCAs: 
    - {{ env "NOMAD_ALLOC_DIR" }}/data/intermediate_ca.crt
  
api:
  dashboard: true
  
ping:
  entryPoint: "traefik"

log:
  level: INFO
#  level: DEBUG

metrics:
  prometheus:
    addEntryPointsLabels: true
    addRoutersLabels: true
    addServicesLabels: true

global:
  sendanonymoususage: false # Periodically send anonymous usage statistics.
  
        EOH
      }

      template {
        destination = "${NOMAD_SECRETS_DIR}/intermediate_ca.crt"
        perms = "600"
        data = <<EOH
{{- with nomadVar "nomad/jobs/traefik" }}{{- .ca_certificate }}{{- end }}
EOH
      }

      template {
        destination = "local/conf/consul.yaml"
        data        = <<EOH
http:
  routers:
    consul:
      rule: Host(`consul.lab.home`)   # FIXME: not working yet, URL error
      service: consul@file
      entrypoints: websecure

  services:
    consul:
      loadBalancer:
        servers:
          - url: "http://homelab-swarm01.home:8500"
          - url: "http://homelab-swarm02.home:8500"
          - url: "http://homelab-swarm04.home:8500"
        EOH
      }

      template {
        destination = "local/conf/nomad.yaml"
        data        = <<EOH
http:
  routers:
    nomad:
      rule: Host(`nomad.lab.home`)
      service: nomad@file
      entrypoints: websecure

  services:
    nomad:
      weighted:
        healthCheck: {}
        services:
        - name: homelab-swarm01
          weight: 10
        - name: homelab-swarm02
          weight: 1
        - name: homelab-swarm04
          weight: 1

    homelab_node01:
      loadBalancer:
        healthCheck:
          path: /v1/status/leader
          interval: 5s
          timeout: 2s
        servers:
          - url: "http://homelab-swarm01.home:4646"

    homelab_node02:
      loadBalancer:
        healthCheck:
          path: /v1/status/leader
          interval: 5s
          timeout: 2s
        servers:
          - url: "http://homelab-swarm02.home:4646"

    homelab_node04:
      loadBalancer:
        healthCheck:
          path: /v1/status/leader
          interval: 5s
          timeout: 2s
        servers:
          - url: "http://homelab-swarm04.home:4646"
        EOH
      }

      template {
        destination = "local/conf/tls.yaml"
        data        = <<EOH
tls:
  options:
    strict_tls:
      minVersion: "VersionTLS13"
      sniStrict: true
        EOH
      }

      resources {
        memory = 256
        cpu    = 400
      }
    }
  }


  # Traefik instance for the DMZ, routes traffic from cloudflared to the desired services
  group "traefik-dmz" {

    network {
      mode = "bridge"

      port "metrics" { to = 8080 } # Prometheus metrics via API port

      port "envoy_metrics_api" { to = 9102 }
      port "envoy_metrics_dmz_http" { to = 9103 }
    }

    service {
      name = "traefik-dmz-api"

      port = 8080

      check {
        type     = "http"
        path     = "/ping"
        interval = "5s"
        timeout  = "2s"
        expose   = true # required for Connect
      }

      meta {
        envoy_metrics_port = "${NOMAD_HOST_PORT_envoy_metrics_api}" # make envoy metrics port available in Consul
        metrics_port = "${NOMAD_HOST_PORT_metrics}"
      }
      connect {
        sidecar_service { 
          proxy {
            config {
              envoy_prometheus_bind_addr = "0.0.0.0:9102"
            }
          }
        }

        sidecar_task {
          resources {
            cpu    = 50
            memory = 48
          }
        }
      }

      tags = [
        "traefik.enable=true",
        "traefik.consulcatalog.connect=true",
        "traefik.http.routers.traefik-dmz.rule=Host(`dmz.lab.home`)",
        "traefik.http.routers.traefik-dmz.entrypoints=websecure"
      ]
    }

    # Cloudflare entrypoint, is bound to localhost:80 in the cloudflared job via Consul Connect
    service {
      name = "traefik-dmz-http"

      port = 80
      tags = ["dmz"]

      meta {
        envoy_metrics_port = "${NOMAD_HOST_PORT_envoy_metrics_dmz_http}" # make envoy metrics port available in Consul
      }
      connect {
        sidecar_service {
          proxy {
            config {
              envoy_prometheus_bind_addr = "0.0.0.0:9103"
            }
          }
        }

        sidecar_task {
          resources {
            cpu    = 50
            memory = 48
          }
        }
      }
    }

    task "server" {

      driver = "docker"

      config {
        image = "traefik:latest"

        args = [ "--configFile=/local/traefik.yaml" ]
      }

      template {
        destination = "${NOMAD_SECRETS_DIR}/certs/origin/schoger.net.crt"
        perms = "600"
        data = <<EOH
{{- with nomadVar "nomad/jobs/traefik" }}{{- .origin_certificate }}{{- end }}
EOH
      }
      template {
        destination = "${NOMAD_SECRETS_DIR}/certs/origin/schoger.net.key"
        perms = "600"
        data = <<EOH
{{- with nomadVar "nomad/jobs/traefik" }}{{- .origin_private_key }}{{- end }}
EOH
      }

      template {
        destination = "local/traefik.yaml"
        data = <<EOH
providers:
  consulcatalog:
    prefix: "dmz"
    connectaware: true
    exposedByDefault: false
    servicename: "traefik-dmz-api" # connects Traefik to the Consul service
    endpoint:
      address: "http://consul.service.consul:8500"

entryPoints:
  cloudflare:
    address: :80
  websecure:
    address: :443
    http:
      tls: 
        options: strict_tls@file
        certResolver: home
  traefik:
    address: :8080

tls:
  certificates:
    - certFile: ${NOMAD_SECRETS_DIR}/certs/origin/schoger.net.crt
      keyFile: ${NOMAD_SECRETS_DIR}/certs/origin/schoger.net.key

api:
  dashboard: true
  insecure: true

ping:
  entryPoint: "traefik"

log:
  level: INFO
#  level: DEBUG

metrics:
  prometheus:
    addEntryPointsLabels: true
    addRoutersLabels: true
    addServicesLabels: true

global:
  sendanonymoususage: false # Periodically send anonymous usage statistics.
EOH
      }

      resources {
        memory = 192
        cpu    = 400
      }
    }
  }
}