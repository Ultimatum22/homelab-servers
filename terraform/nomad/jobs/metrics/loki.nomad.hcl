job "loki" {
  datacenters = ["dc1"]
  type        = "service"

  group "loki" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "loki" {
      driver = "docker"

      config {
        image = "grafana/loki:2.8.7"

        args = [
          "-config.file",
          "/etc/loki/local-config.yaml",
        ]

        port_map {
          loki_port = 3100
        }

        volumes = [
          "local/loki-config.yaml:/etc/loki/local-config.yaml",
        ]
      }

      resources {
        cpu    = 50
        memory = 32

        network {
          mbits = 1
          port  "loki_port"{}
        }
      }

      service {
        name = "loki"
        port = "loki_port"

        check {
          type     = "http"
          path     = "/health"
          interval = "10s"
          timeout  = "2s"
        }
      }


      template {
        data = <<EOF
auth_enabled: false

server:
  http_listen_port: 3100

common:
  ring:
    instance_addr: 127.0.0.1
    kvstore:
      store: inmemory
  replication_factor: 1
  path_prefix: /tmp/loki

schema_config:
  configs:
    - from: 2020-05-15
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: {{ env "NOMAD_TASK_DIR" }}/index

  filesystem:
    directory: {{ env "NOMAD_TASK_DIR" }}/chunks

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h

chunk_store_config:
  max_look_back_period: 168h

table_manager:
  retention_deletes_enabled: true
  retention_period: 168h

EOF
        destination = "local/loki-config.yaml"
      }
    }
  }
}
