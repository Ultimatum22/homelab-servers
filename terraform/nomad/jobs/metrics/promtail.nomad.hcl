job "promtail" {
  datacenters = ["dc1"]
  type = "system"

  group "promtail" {

    network {
      mode = "bridge"

      port "promtail" {
        to = 9080
      }
    }

    service {
      name = "promtail"
      port = "promtail"
    }

    task "promtail" {
      driver = "docker"

      config {
        image = "grafana/promtail:2.9.4"
        args = ["-config.file=$${NOMAD_TASK_DIR}/promtail.yml"]
        ports = ["promtail"]

        # Bind mount host machine-id and log directories

        // mount {
        //   type = "bind"
        //   source = "/etc/machine-id"
        //   target = "/etc/machine-id"
        //   readonly = true
        // }

        // mount {
        //   type = "bind"
        //   source = "/var/log/journal/"
        //   target = "/var/log/journal/"
        //   readonly = true
        // }

        // mount {
        //   type = "bind"
        //   source = "/run/log/journal/"
        //   target = "/run/log/journal/"
        //   readonly = true
        // }

        # mount {
        #   type = "bind"
        #   source = "/var/log/audit"
        #   target = "/var/log/audit"
        #   readonly = true
        # }
      }

      template {
        data = <<EOF
---
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: flog_scrape
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 5s
        filters:
          - name: label
            values: ["logging=promtail"]
    relabel_configs:
      - source_labels: ['__meta_docker_container_name']
        regex: '/(.*)'
        target_label: 'container'
      - source_labels: ['__meta_docker_container_log_stream']
        target_label: 'logstream'
      - source_labels: ['__meta_docker_container_label_logging_jobname']
        target_label: 'job'
EOF
        destination = "$${NOMAD_TASK_DIR}/promtail.yml"
      }

      resources {
        cpu = 50
        memory = 100
      }
    }
  }
}
