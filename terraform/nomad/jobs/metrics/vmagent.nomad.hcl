job "vmagent" {

  type        = "service"

  group "vmagent" {
    count = 1

    network {
      mode = "bridge"

      port "vmagent-http" {
        to = 8429
      }
    }

    task "vmagent" {
      driver = "docker"

      config {
        image = "victoriametrics/vmagent:v1.93.12"
        args = [
          "--promscrape.config=${NOMAD_TASK_DIR}/prometheus.yml",
          "--remoteWrite.url=${VICTORIAMETRICS_ADDR}"
        ]
      }

      template {
        data        = <<EOF
global:
  scrape_interval: 10s
  external_labels:
    env: "dev"
    cluster: "local"

scrape_configs:
  - job_name: "nomad-agent"
    metrics_path: "/v1/metrics?format=prometheus"
    static_configs:
      - targets: ["{{ env "NOMAD_IP_vmagent_http" }}:4646"]
        labels:
          role: agent
    relabel_configs:
      - source_labels: [__address__]
        regex: "([^:]+):.+"
        target_label: "hostname"
        replacement: "nomad-agent-$1"
EOF
        destination = "local/prometheus.yml"
        change_mode = "restart"
      }

      template {
        data = <<EOF
{{- range nomadService "vicky-web" }}
VICTORIAMETRICS_ADDR=http://{{ .Address }}:{{ .Port }}/api/v1/write
{{ end -}}
EOF

        destination = "local/env"
        env         = true
      }

      resources {
        cpu    = 256
        memory = 300
      }
    }
  }
}
