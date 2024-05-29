job "grafana" {

  type        = "service"

  group "grafana" {
    count = 1

    volume "grafana" {
      type      = "host"
      read_only = false
      source    = "grafana"
    }

    network {
      mode = "bridge"

      port "grafana-http" {
        to = 3000
      }
    }

    task "grafana" {
      driver = "docker"

      service {
        name     = "grafana-web"
        provider = "nomad"
        tags     = ["grafana", "web"]
        port     = "grafana-http"
      }

      env {
        GF_LOG_LEVEL          = "DEBUG"
        GF_LOG_MODE           = "console"
        GF_SERVER_HTTP_PORT   = "$${NOMAD_PORT_http}"
        GF_PATHS_PROVISIONING = "/local/grafana/provisioning"
      }

      volume_mount {
        volume      = "grafana"
        destination = "/var/lib/grafana"
        read_only   = false
      }

      user = "root"

      config {
        image = "grafana/grafana:10.2.4"
        ports = ["grafana-http"]
      }

      resources {
        cpu    = 256
        memory = 300
      }

      template {
        data        = <<EOF
apiVersion: 1
datasources:
  - name: VictoriaMetrics
    type: prometheus
    access: proxy
    {{- range nomadService "vicky-web" }}
    url: http://{{.Address}}:{{.Port}}
    {{ end -}}
EOF
        destination = "/local/grafana/provisioning/datasources/datasources.yaml"
      }

      template {
        data        = <<EOF
apiVersion: 1
providers:
  - name: dashboards
    type: file
    updateIntervalSeconds: 30
    options:
      foldersFromFilesStructure: true
      path: /local/grafana/provisioning/dashboards
EOF
        destination = "/local/grafana/provisioning/dashboards/dashboards.yaml"
      }

      template {
        data            = <<EOF
        {
            "__inputs": [
              {
                "name": "DS_PROMETHEUS",
                "label": "Prometheus",
                "description": "",
                "type": "datasource",
                "pluginId": "prometheus",
                "pluginName": "Prometheus"
              }
            ],
            "__elements": {},
            "__requires": [
              {
                "type": "grafana",
                "id": "grafana",
                "name": "Grafana",
                "version": "9.1.4"
              },
              {
                "type": "datasource",
                "id": "prometheus",
                "name": "Prometheus",
                "version": "1.0.0"
              },
              {
                "type": "panel",
                "id": "timeseries",
                "name": "Time series",
                "version": ""
              }
            ],
            "annotations": {
              "list": [
                {
                  "builtIn": 1,
                  "datasource": {
                    "type": "grafana",
                    "uid": "-- Grafana --"
                  },
                  "enable": true,
                  "hide": true,
                  "iconColor": "rgba(0, 211, 255, 1)",
                  "name": "Annotations & Alerts",
                  "target": {
                    "limit": 100,
                    "matchAny": false,
                    "tags": [],
                    "type": "dashboard"
                  },
                  "type": "dashboard"
                }
              ]
            },
            "editable": true,
            "fiscalYearStartMonth": 0,
            "graphTooltip": 0,
            "id": null,
            "links": [],
            "liveNow": false,
            "panels": [
              {
                "collapsed": false,
                "gridPos": {
                  "h": 1,
                  "w": 24,
                  "x": 0,
                  "y": 0
                },
                "id": 10,
                "panels": [],
                "title": "CPU",
                "type": "row"
              },
              {
                "datasource": {
                  "type": "prometheus",
                  "uid": "${DS_PROMETHEUS}"
                },
                "fieldConfig": {
                  "defaults": {
                    "color": {
                      "mode": "palette-classic"
                    },
                    "custom": {
                      "axisCenteredZero": false,
                      "axisColorMode": "text",
                      "axisLabel": "",
                      "axisPlacement": "auto",
                      "barAlignment": 0,
                      "drawStyle": "line",
                      "fillOpacity": 46,
                      "gradientMode": "hue",
                      "hideFrom": {
                        "legend": false,
                        "tooltip": false,
                        "viz": false
                      },
                      "lineInterpolation": "linear",
                      "lineWidth": 1,
                      "pointSize": 5,
                      "scaleDistribution": {
                        "type": "linear"
                      },
                      "showPoints": "auto",
                      "spanNulls": false,
                      "stacking": {
                        "group": "A",
                        "mode": "none"
                      },
                      "thresholdsStyle": {
                        "mode": "off"
                      }
                    },
                    "mappings": [],
                    "max": 1,
                    "min": 0,
                    "thresholds": {
                      "mode": "absolute",
                      "steps": [
                        {
                          "color": "green",
                          "value": null
                        },
                        {
                          "color": "red",
                          "value": 80
                        }
                      ]
                    },
                    "unit": "percentunit"
                  },
                  "overrides": []
                },
                "gridPos": {
                  "h": 8,
                  "w": 24,
                  "x": 0,
                  "y": 1
                },
                "id": 21,
                "options": {
                  "legend": {
                    "calcs": [
                      "lastNotNull",
                      "max",
                      "mean"
                    ],
                    "displayMode": "table",
                    "placement": "right",
                    "showLegend": true,
                    "sortBy": "Last *",
                    "sortDesc": true
                  },
                  "tooltip": {
                    "mode": "single",
                    "sort": "none"
                  }
                },
                "targets": [
                  {
                    "datasource": {
                      "type": "prometheus",
                      "uid": "${DS_PROMETHEUS}"
                    },
                    "editorMode": "code",
                    "expr": "sum by (task,alloc_id)(nomad_client_allocs_cpu_total_ticks{exported_job=\"$workload\",task_group=\"$group\"}) / sum by (task,alloc_id)(nomad_client_allocs_cpu_allocated{exported_job=\"$workload\",task_group=\"$group\"})",
                    "legendFormat": "{{task}} - {{alloc_id}}",
                    "range": true,
                    "refId": "A"
                  }
                ],
                "title": "CPU %",
                "type": "timeseries"
              },
              {
                "datasource": {
                  "type": "prometheus",
                  "uid": "${DS_PROMETHEUS}"
                },
                "description": "Total CPU resources consumed by the task across all cores",
                "fieldConfig": {
                  "defaults": {
                    "color": {
                      "mode": "palette-classic"
                    },
                    "custom": {
                      "axisCenteredZero": false,
                      "axisColorMode": "text",
                      "axisLabel": "",
                      "axisPlacement": "auto",
                      "barAlignment": 0,
                      "drawStyle": "line",
                      "fillOpacity": 50,
                      "gradientMode": "hue",
                      "hideFrom": {
                        "legend": false,
                        "tooltip": false,
                        "viz": false
                      },
                      "lineInterpolation": "linear",
                      "lineWidth": 1,
                      "pointSize": 5,
                      "scaleDistribution": {
                        "type": "linear"
                      },
                      "showPoints": "auto",
                      "spanNulls": false,
                      "stacking": {
                        "group": "A",
                        "mode": "none"
                      },
                      "thresholdsStyle": {
                        "mode": "off"
                      }
                    },
                    "mappings": [],
                    "min": 0,
                    "thresholds": {
                      "mode": "absolute",
                      "steps": [
                        {
                          "color": "green",
                          "value": null
                        },
                        {
                          "color": "red",
                          "value": 80
                        }
                      ]
                    },
                    "unit": "short"
                  },
                  "overrides": []
                },
                "gridPos": {
                  "h": 8,
                  "w": 12,
                  "x": 0,
                  "y": 9
                },
                "id": 19,
                "options": {
                  "legend": {
                    "calcs": [
                      "lastNotNull",
                      "max",
                      "mean"
                    ],
                    "displayMode": "table",
                    "placement": "right",
                    "showLegend": true,
                    "sortBy": "Last *",
                    "sortDesc": true
                  },
                  "tooltip": {
                    "mode": "single",
                    "sort": "none"
                  }
                },
                "targets": [
                  {
                    "datasource": {
                      "type": "prometheus",
                      "uid": "${DS_PROMETHEUS}"
                    },
                    "editorMode": "code",
                    "expr": "sum by (task,alloc_id)(nomad_client_allocs_cpu_total_percent{exported_job=\"$workload\",task_group=\"$group\"})/100",
                    "legendFormat": "{{task}} - {{alloc_id}}",
                    "range": true,
                    "refId": "A"
                  }
                ],
                "title": "CPU Usage (Cores) ",
                "type": "timeseries"
              },
              {
                "datasource": {
                  "type": "prometheus",
                  "uid": "${DS_PROMETHEUS}"
                },
                "description": "Total time that the task was throttled",
                "fieldConfig": {
                  "defaults": {
                    "color": {
                      "mode": "palette-classic"
                    },
                    "custom": {
                      "axisCenteredZero": false,
                      "axisColorMode": "text",
                      "axisLabel": "",
                      "axisPlacement": "auto",
                      "barAlignment": 0,
                      "drawStyle": "line",
                      "fillOpacity": 0,
                      "gradientMode": "none",
                      "hideFrom": {
                        "legend": false,
                        "tooltip": false,
                        "viz": false
                      },
                      "lineInterpolation": "linear",
                      "lineWidth": 1,
                      "pointSize": 5,
                      "scaleDistribution": {
                        "type": "linear"
                      },
                      "showPoints": "auto",
                      "spanNulls": false,
                      "stacking": {
                        "group": "A",
                        "mode": "none"
                      },
                      "thresholdsStyle": {
                        "mode": "off"
                      }
                    },
                    "mappings": [],
                    "min": 0,
                    "thresholds": {
                      "mode": "absolute",
                      "steps": [
                        {
                          "color": "green",
                          "value": null
                        },
                        {
                          "color": "red",
                          "value": 80
                        }
                      ]
                    },
                    "unit": "ns"
                  },
                  "overrides": []
                },
                "gridPos": {
                  "h": 8,
                  "w": 12,
                  "x": 12,
                  "y": 9
                },
                "id": 23,
                "options": {
                  "legend": {
                    "calcs": [],
                    "displayMode": "list",
                    "placement": "bottom",
                    "showLegend": true
                  },
                  "tooltip": {
                    "mode": "single",
                    "sort": "none"
                  }
                },
                "targets": [
                  {
                    "datasource": {
                      "type": "prometheus",
                      "uid": "${DS_PROMETHEUS}"
                    },
                    "editorMode": "code",
                    "expr": "sum by (task,alloc_id)(nomad_client_allocs_cpu_throttled_time{exported_job=\"$workload\",task_group=\"$group\"})",
                    "legendFormat": "{{task}} - {{alloc_id}}",
                    "range": true,
                    "refId": "A"
                  }
                ],
                "title": "CPU Throttled Time ",
                "type": "timeseries"
              },
              {
                "collapsed": false,
                "gridPos": {
                  "h": 1,
                  "w": 24,
                  "x": 0,
                  "y": 17
                },
                "id": 12,
                "panels": [],
                "title": "Memory",
                "type": "row"
              },
              {
                "datasource": {
                  "type": "prometheus",
                  "uid": "${DS_PROMETHEUS}"
                },
                "fieldConfig": {
                  "defaults": {
                    "color": {
                      "mode": "palette-classic"
                    },
                    "custom": {
                      "axisCenteredZero": false,
                      "axisColorMode": "text",
                      "axisLabel": "",
                      "axisPlacement": "auto",
                      "barAlignment": 0,
                      "drawStyle": "line",
                      "fillOpacity": 38,
                      "gradientMode": "hue",
                      "hideFrom": {
                        "legend": false,
                        "tooltip": false,
                        "viz": false
                      },
                      "lineInterpolation": "linear",
                      "lineWidth": 1,
                      "pointSize": 5,
                      "scaleDistribution": {
                        "type": "linear"
                      },
                      "showPoints": "auto",
                      "spanNulls": false,
                      "stacking": {
                        "group": "A",
                        "mode": "none"
                      },
                      "thresholdsStyle": {
                        "mode": "off"
                      }
                    },
                    "mappings": [],
                    "max": 1,
                    "min": 0,
                    "thresholds": {
                      "mode": "absolute",
                      "steps": [
                        {
                          "color": "green",
                          "value": null
                        },
                        {
                          "color": "red",
                          "value": 80
                        }
                      ]
                    },
                    "unit": "percentunit"
                  },
                  "overrides": []
                },
                "gridPos": {
                  "h": 9,
                  "w": 24,
                  "x": 0,
                  "y": 18
                },
                "id": 25,
                "options": {
                  "legend": {
                    "calcs": [
                      "lastNotNull",
                      "max",
                      "mean"
                    ],
                    "displayMode": "table",
                    "placement": "right",
                    "showLegend": true
                  },
                  "tooltip": {
                    "mode": "single",
                    "sort": "none"
                  }
                },
                "targets": [
                  {
                    "datasource": {
                      "type": "prometheus",
                      "uid": "${DS_PROMETHEUS}"
                    },
                    "editorMode": "code",
                    "expr": "sum by (task,alloc_id)(nomad_client_allocs_memory_usage{exported_job=\"$workload\",task_group=\"$group\"}) / sum by (task,alloc_id)(nomad_client_allocs_memory_allocated{exported_job=\"$workload\",task_group=\"$group\"})",
                    "legendFormat": "{{task}} - {{alloc_id}}",
                    "range": true,
                    "refId": "A"
                  }
                ],
                "title": "Memory %",
                "type": "timeseries"
              }
            ],
            "schemaVersion": 37,
            "style": "dark",
            "tags": [
              "nomad",
              "nomad-allocs"
            ],
            "templating": {
              "list": [
                {
                  "current": {
                    "selected": false,
                    "text": "Prometheus",
                    "value": "Prometheus"
                  },
                  "hide": 0,
                  "includeAll": false,
                  "label": "datasource",
                  "multi": false,
                  "name": "DS_PROMETHEUS",
                  "options": [],
                  "query": "prometheus",
                  "refresh": 1,
                  "regex": "",
                  "skipUrlSync": false,
                  "type": "datasource"
                },
                {
                  "current": {},
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "definition": "label_values(nomad_client_uptime, cluster)",
                  "hide": 0,
                  "includeAll": false,
                  "label": "Cluster",
                  "multi": false,
                  "name": "cluster",
                  "options": [],
                  "query": {
                    "query": "label_values(nomad_client_uptime, cluster)",
                    "refId": "StandardVariableQuery"
                  },
                  "refresh": 1,
                  "regex": "",
                  "skipUrlSync": false,
                  "sort": 0,
                  "type": "query"
                },
                {
                  "current": {},
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "definition": "label_values(nomad_client_allocs_cpu_allocated{cluster=\"$cluster\"}, namespace)",
                  "hide": 0,
                  "includeAll": false,
                  "label": "Namespace",
                  "multi": false,
                  "name": "namespace",
                  "options": [],
                  "query": {
                    "query": "label_values(nomad_client_allocs_cpu_allocated{cluster=\"$cluster\"}, namespace)",
                    "refId": "StandardVariableQuery"
                  },
                  "refresh": 1,
                  "regex": "",
                  "skipUrlSync": false,
                  "sort": 0,
                  "type": "query"
                },
                {
                  "current": {},
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "definition": "label_values(nomad_client_allocs_cpu_allocated{cluster=\"$cluster\",namespace=\"$namespace\"}, exported_job)",
                  "hide": 0,
                  "includeAll": false,
                  "label": "Workload",
                  "multi": false,
                  "name": "workload",
                  "options": [],
                  "query": {
                    "query": "label_values(nomad_client_allocs_cpu_allocated{cluster=\"$cluster\",namespace=\"$namespace\"}, exported_job)",
                    "refId": "StandardVariableQuery"
                  },
                  "refresh": 1,
                  "regex": "",
                  "skipUrlSync": false,
                  "sort": 0,
                  "type": "query"
                },
                {
                  "current": {},
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "definition": "label_values(nomad_client_allocs_cpu_allocated{cluster=\"$cluster\",namespace=\"$namespace\",exported_job=\"$workload\"}, task_group)",
                  "hide": 0,
                  "includeAll": false,
                  "label": "Task Group",
                  "multi": false,
                  "name": "group",
                  "options": [],
                  "query": {
                    "query": "label_values(nomad_client_allocs_cpu_allocated{cluster=\"$cluster\",namespace=\"$namespace\",exported_job=\"$workload\"}, task_group)",
                    "refId": "StandardVariableQuery"
                  },
                  "refresh": 1,
                  "regex": "",
                  "skipUrlSync": false,
                  "sort": 0,
                  "type": "query"
                }
              ]
            },
            "time": {
              "from": "now-6h",
              "to": "now"
            },
            "timepicker": {},
            "timezone": "",
            "title": "Allocations",
            "uid": "5XxwU0GVz",
            "version": 1,
            "weekStart": ""
          }
        EOF
        destination     = "local/grafana/provisioning/dashboards/nomad/allocations.json"
        left_delimiter  = "[["
        right_delimiter = "]]"
      }
      template {
        data            = <<EOF
        {
          "__inputs": [
            {
              "name": "DS_PROMETHEUS",
              "label": "Prometheus",
              "description": "",
              "type": "datasource",
              "pluginId": "prometheus",
              "pluginName": "Prometheus"
            }
          ],
          "__elements": {},
          "__requires": [
            {
              "type": "grafana",
              "id": "grafana",
              "name": "Grafana",
              "version": "9.1.4"
            },
            {
              "type": "datasource",
              "id": "prometheus",
              "name": "Prometheus",
              "version": "1.0.0"
            },
            {
              "type": "panel",
              "id": "stat",
              "name": "Stat",
              "version": ""
            },
            {
              "type": "panel",
              "id": "table",
              "name": "Table",
              "version": ""
            },
            {
              "type": "panel",
              "id": "timeseries",
              "name": "Time series",
              "version": ""
            }
          ],
          "annotations": {
            "list": [
              {
                "builtIn": 1,
                "datasource": {
                  "type": "grafana",
                  "uid": "-- Grafana --"
                },
                "enable": true,
                "hide": true,
                "iconColor": "rgba(0, 211, 255, 1)",
                "name": "Annotations & Alerts",
                "target": {
                  "limit": 100,
                  "matchAny": false,
                  "tags": [],
                  "type": "dashboard"
                },
                "type": "dashboard"
              }
            ]
          },
          "editable": true,
          "fiscalYearStartMonth": 0,
          "graphTooltip": 0,
          "id": null,
          "links": [],
          "liveNow": false,
          "panels": [
            {
              "collapsed": false,
              "gridPos": {
                "h": 1,
                "w": 24,
                "x": 0,
                "y": 0
              },
              "id": 2,
              "panels": [],
              "title": "Headlines",
              "type": "row"
            },
            {
              "datasource": {
                "type": "prometheus",
                "uid": "${DS_PROMETHEUS}"
              },
              "fieldConfig": {
                "defaults": {
                  "color": {
                    "fixedColor": "purple",
                    "mode": "fixed"
                  },
                  "mappings": [],
                  "thresholds": {
                    "mode": "absolute",
                    "steps": [
                      {
                        "color": "green",
                        "value": null
                      },
                      {
                        "color": "red",
                        "value": 80
                      }
                    ]
                  },
                  "unit": "percentunit"
                },
                "overrides": []
              },
              "gridPos": {
                "h": 5,
                "w": 4,
                "x": 0,
                "y": 1
              },
              "id": 4,
              "options": {
                "colorMode": "value",
                "graphMode": "area",
                "justifyMode": "auto",
                "orientation": "auto",
                "reduceOptions": {
                  "calcs": [
                    "lastNotNull"
                  ],
                  "fields": "",
                  "values": false
                },
                "textMode": "auto"
              },
              "pluginVersion": "9.1.4",
              "targets": [
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "expr": "sum by (cluster) (nomad_client_host_cpu_total{cluster=\"$cluster\"}) / (sum by (cluster) (nomad_client_host_cpu_total{cluster=\"$cluster\"}) + sum by (cluster) (nomad_client_host_cpu_idle{cluster=\"$cluster\"}))",
                  "legendFormat": "__auto",
                  "range": true,
                  "refId": "A"
                }
              ],
              "title": "CPU Utilisation",
              "type": "stat"
            },
            {
              "datasource": {
                "type": "prometheus",
                "uid": "${DS_PROMETHEUS}"
              },
              "fieldConfig": {
                "defaults": {
                  "color": {
                    "fixedColor": "purple",
                    "mode": "fixed"
                  },
                  "mappings": [],
                  "thresholds": {
                    "mode": "percentage",
                    "steps": [
                      {
                        "color": "green",
                        "value": null
                      }
                    ]
                  },
                  "unit": "percentunit"
                },
                "overrides": []
              },
              "gridPos": {
                "h": 5,
                "w": 4,
                "x": 4,
                "y": 1
              },
              "id": 7,
              "options": {
                "colorMode": "value",
                "graphMode": "area",
                "justifyMode": "auto",
                "orientation": "auto",
                "reduceOptions": {
                  "calcs": [
                    "lastNotNull"
                  ],
                  "fields": "",
                  "values": false
                },
                "textMode": "auto"
              },
              "pluginVersion": "9.1.4",
              "targets": [
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "expr": "sum by (cluster) (nomad_client_allocated_cpu{cluster=\"$cluster\"}) / (sum by (cluster) (nomad_client_allocated_cpu{cluster=\"$cluster\"}) + sum by (cluster) (nomad_client_unallocated_cpu{cluster=\"$cluster\"}))",
                  "legendFormat": "__auto",
                  "range": true,
                  "refId": "A"
                }
              ],
              "title": "CPU Allocations",
              "type": "stat"
            },
            {
              "datasource": {
                "type": "prometheus",
                "uid": "${DS_PROMETHEUS}"
              },
              "fieldConfig": {
                "defaults": {
                  "color": {
                    "fixedColor": "blue",
                    "mode": "fixed"
                  },
                  "mappings": [],
                  "thresholds": {
                    "mode": "absolute",
                    "steps": [
                      {
                        "color": "green",
                        "value": null
                      }
                    ]
                  },
                  "unit": "percentunit"
                },
                "overrides": []
              },
              "gridPos": {
                "h": 5,
                "w": 4,
                "x": 8,
                "y": 1
              },
              "id": 5,
              "options": {
                "colorMode": "value",
                "graphMode": "area",
                "justifyMode": "auto",
                "orientation": "auto",
                "reduceOptions": {
                  "calcs": [
                    "lastNotNull"
                  ],
                  "fields": "",
                  "values": false
                },
                "textMode": "auto"
              },
              "pluginVersion": "9.1.4",
              "targets": [
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "expr": "sum by (cluster) (nomad_client_host_memory_used{cluster=\"$cluster\"}) / (sum by (cluster) (nomad_client_host_memory_total{cluster=\"$cluster\"}))",
                  "legendFormat": "__auto",
                  "range": true,
                  "refId": "A"
                }
              ],
              "title": "Memory Utilisation",
              "type": "stat"
            },
            {
              "datasource": {
                "type": "prometheus",
                "uid": "${DS_PROMETHEUS}"
              },
              "fieldConfig": {
                "defaults": {
                  "color": {
                    "fixedColor": "blue",
                    "mode": "fixed"
                  },
                  "mappings": [],
                  "thresholds": {
                    "mode": "absolute",
                    "steps": [
                      {
                        "color": "green",
                        "value": null
                      }
                    ]
                  },
                  "unit": "percentunit"
                },
                "overrides": []
              },
              "gridPos": {
                "h": 5,
                "w": 4,
                "x": 12,
                "y": 1
              },
              "id": 8,
              "options": {
                "colorMode": "value",
                "graphMode": "area",
                "justifyMode": "auto",
                "orientation": "auto",
                "reduceOptions": {
                  "calcs": [
                    "lastNotNull"
                  ],
                  "fields": "",
                  "values": false
                },
                "textMode": "auto"
              },
              "pluginVersion": "9.1.4",
              "targets": [
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "expr": "sum by (cluster) (nomad_client_allocated_memory{cluster=\"$cluster\"}) / (sum by (cluster) (nomad_client_allocated_memory{cluster=\"$cluster\"}) + sum by (cluster) (nomad_client_unallocated_memory{cluster=\"$cluster\"}))",
                  "legendFormat": "__auto",
                  "range": true,
                  "refId": "A"
                }
              ],
              "title": "Memory Allocations",
              "type": "stat"
            },
            {
              "datasource": {
                "type": "prometheus",
                "uid": "${DS_PROMETHEUS}"
              },
              "fieldConfig": {
                "defaults": {
                  "color": {
                    "fixedColor": "semi-dark-orange",
                    "mode": "fixed"
                  },
                  "mappings": [],
                  "thresholds": {
                    "mode": "absolute",
                    "steps": [
                      {
                        "color": "green",
                        "value": null
                      },
                      {
                        "color": "red",
                        "value": 80
                      }
                    ]
                  },
                  "unit": "percentunit"
                },
                "overrides": []
              },
              "gridPos": {
                "h": 5,
                "w": 4,
                "x": 16,
                "y": 1
              },
              "id": 6,
              "options": {
                "colorMode": "value",
                "graphMode": "area",
                "justifyMode": "auto",
                "orientation": "auto",
                "reduceOptions": {
                  "calcs": [
                    "lastNotNull"
                  ],
                  "fields": "",
                  "values": false
                },
                "textMode": "auto"
              },
              "pluginVersion": "9.1.4",
              "targets": [
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "expr": "sum by (cluster) (nomad_client_host_disk_used{cluster=\"$cluster\"}) / (sum by (cluster) (nomad_client_host_disk_size{cluster=\"$cluster\"}))",
                  "legendFormat": "__auto",
                  "range": true,
                  "refId": "A"
                }
              ],
              "title": "Disk Utilisation",
              "type": "stat"
            },
            {
              "collapsed": false,
              "gridPos": {
                "h": 1,
                "w": 24,
                "x": 0,
                "y": 6
              },
              "id": 19,
              "panels": [],
              "title": "Clients",
              "type": "row"
            },
            {
              "datasource": {
                "type": "prometheus",
                "uid": "${DS_PROMETHEUS}"
              },
              "description": "",
              "fieldConfig": {
                "defaults": {
                  "color": {
                    "mode": "thresholds"
                  },
                  "custom": {
                    "align": "auto",
                    "displayMode": "auto",
                    "inspect": false
                  },
                  "links": [],
                  "mappings": [],
                  "thresholds": {
                    "mode": "absolute",
                    "steps": [
                      {
                        "color": "green",
                        "value": null
                      }
                    ]
                  }
                },
                "overrides": [
                  {
                    "matcher": {
                      "id": "byName",
                      "options": "Node ID"
                    },
                    "properties": [
                      {
                        "id": "custom.width",
                        "value": 130
                      }
                    ]
                  },
                  {
                    "matcher": {
                      "id": "byName",
                      "options": "Node class"
                    },
                    "properties": [
                      {
                        "id": "custom.width",
                        "value": 90
                      }
                    ]
                  },
                  {
                    "matcher": {
                      "id": "byName",
                      "options": "Eligibility"
                    },
                    "properties": [
                      {
                        "id": "custom.width",
                        "value": 120
                      }
                    ]
                  },
                  {
                    "matcher": {
                      "id": "byName",
                      "options": "Status"
                    },
                    "properties": [
                      {
                        "id": "custom.width",
                        "value": 102
                      }
                    ]
                  },
                  {
                    "matcher": {
                      "id": "byName",
                      "options": "Uptime"
                    },
                    "properties": [
                      {
                        "id": "unit",
                        "value": "s"
                      },
                      {
                        "id": "custom.width",
                        "value": 100
                      }
                    ]
                  },
                  {
                    "matcher": {
                      "id": "byName",
                      "options": "CPU"
                    },
                    "properties": [
                      {
                        "id": "unit",
                        "value": "percent"
                      },
                      {
                        "id": "color",
                        "value": {
                          "mode": "continuous-BlPu"
                        }
                      },
                      {
                        "id": "custom.displayMode",
                        "value": "color-background"
                      },
                      {
                        "id": "min",
                        "value": 0
                      },
                      {
                        "id": "max",
                        "value": 100
                      },
                      {
                        "id": "custom.width",
                        "value": 145
                      }
                    ]
                  },
                  {
                    "matcher": {
                      "id": "byName",
                      "options": "Memory"
                    },
                    "properties": [
                      {
                        "id": "unit",
                        "value": "percent"
                      },
                      {
                        "id": "color",
                        "value": {
                          "mode": "continuous-BlPu"
                        }
                      },
                      {
                        "id": "custom.displayMode",
                        "value": "color-background"
                      },
                      {
                        "id": "min",
                        "value": 0
                      },
                      {
                        "id": "max",
                        "value": 100
                      },
                      {
                        "id": "custom.width",
                        "value": 116
                      }
                    ]
                  },
                  {
                    "matcher": {
                      "id": "byName",
                      "options": "Disk"
                    },
                    "properties": [
                      {
                        "id": "unit",
                        "value": "percent"
                      },
                      {
                        "id": "color",
                        "value": {
                          "mode": "continuous-BlPu"
                        }
                      },
                      {
                        "id": "custom.displayMode",
                        "value": "color-background"
                      },
                      {
                        "id": "min",
                        "value": 0
                      },
                      {
                        "id": "max",
                        "value": 100
                      },
                      {
                        "id": "custom.width",
                        "value": 197
                      }
                    ]
                  },
                  {
                    "matcher": {
                      "id": "byName",
                      "options": "Allocs"
                    },
                    "properties": [
                      {
                        "id": "custom.width",
                        "value": 138
                      },
                      {
                        "id": "custom.displayMode",
                        "value": "color-text"
                      },
                      {
                        "id": "color",
                        "value": {
                          "mode": "continuous-BlPu"
                        }
                      },
                      {
                        "id": "thresholds",
                        "value": {
                          "mode": "absolute",
                          "steps": [
                            {
                              "color": "red",
                              "value": null
                            }
                          ]
                        }
                      }
                    ]
                  },
                  {
                    "matcher": {
                      "id": "byName",
                      "options": "Client"
                    },
                    "properties": [
                      {
                        "id": "custom.width",
                        "value": 276
                      }
                    ]
                  },
                  {
                    "matcher": {
                      "id": "byName",
                      "options": "Instance"
                    },
                    "properties": [
                      {
                        "id": "custom.width",
                        "value": 546
                      }
                    ]
                  }
                ]
              },
              "gridPos": {
                "h": 9,
                "w": 24,
                "x": 0,
                "y": 7
              },
              "id": 23,
              "options": {
                "footer": {
                  "fields": "",
                  "reducer": [
                    "sum"
                  ],
                  "show": false
                },
                "showHeader": true,
                "sortBy": []
              },
              "pluginVersion": "9.1.4",
              "targets": [
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "exemplar": false,
                  "expr": "nomad_client_uptime{cluster=\"$cluster\"}",
                  "format": "table",
                  "instant": true,
                  "interval": "",
                  "legendFormat": "uptime",
                  "refId": "A"
                },
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "exemplar": false,
                  "expr": "nomad_client_allocations_running{cluster=\"$cluster\"}",
                  "format": "table",
                  "hide": false,
                  "instant": true,
                  "interval": "",
                  "legendFormat": "allocations running",
                  "refId": "B"
                },
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "exemplar": false,
                  "expr": "100 -\nnomad_client_unallocated_cpu{role=\"nomad-client\"}\n/\n(nomad_client_allocated_cpu{role=\"nomad-client\"}\n+ nomad_client_unallocated_cpu{role=\"nomad-client\"}) * 100",
                  "format": "table",
                  "hide": false,
                  "instant": true,
                  "interval": "",
                  "legendFormat": "cpu utilization",
                  "refId": "C"
                },
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "exemplar": false,
                  "expr": "100 -\nnomad_client_unallocated_memory{role=\"nomad-client\"}\n/\n(nomad_client_allocated_memory{role=\"nomad-client\"}\n+ nomad_client_unallocated_memory{role=\"nomad-client\"}) * 100",
                  "format": "table",
                  "hide": false,
                  "instant": true,
                  "interval": "",
                  "legendFormat": "memory utilization",
                  "refId": "D"
                },
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "exemplar": false,
                  "expr": "100 -\nnomad_client_unallocated_disk{role=\"nomad-client\"}\n/\n(nomad_client_allocated_disk{role=\"nomad-client\"}\n+ nomad_client_unallocated_disk{role=\"nomad-client\"}) * 100",
                  "format": "table",
                  "hide": false,
                  "instant": true,
                  "interval": "",
                  "legendFormat": "disk utilization",
                  "refId": "E"
                }
              ],
              "title": "Clients",
              "transformations": [
                {
                  "id": "seriesToColumns",
                  "options": {
                    "byField": "instance"
                  }
                },
                {
                  "id": "filterFieldsByName",
                  "options": {
                    "include": {
                      "names": [
                        "instance",
                        "instance_name 1",
                        "instance_private_ip 1",
                        "node_class 1",
                        "node_id 1",
                        "node_scheduling_eligibility 1",
                        "node_status 1",
                        "Value #A",
                        "instance_name 2",
                        "instance_private_ip 2",
                        "Value #B",
                        "instance_name 3",
                        "instance_private_ip 3",
                        "Value #C",
                        "instance_name 4",
                        "instance_private_ip 4",
                        "Value #D",
                        "instance_name 5",
                        "Value #E"
                      ],
                      "pattern": "instance|node_.* 1|Value .*"
                    }
                  }
                },
                {
                  "id": "organize",
                  "options": {
                    "excludeByName": {
                      "instance_name 1": false,
                      "instance_name 2": true,
                      "instance_name 3": true,
                      "instance_name 4": true,
                      "instance_name 5": true,
                      "instance_private_ip 1": true,
                      "instance_private_ip 2": true,
                      "instance_private_ip 3": true,
                      "instance_private_ip 4": true,
                      "instance_private_ip 5": true,
                      "node_class 1": true,
                      "node_id": false,
                      "node_scheduling_eligibility 1": false,
                      "node_status 1": false
                    },
                    "indexByName": {
                      "Value #A": 6,
                      "Value #B": 7,
                      "Value #C": 13,
                      "Value #D": 16,
                      "Value #E": 19,
                      "instance": 1,
                      "instance_name 1": 0,
                      "instance_name 2": 9,
                      "instance_name 3": 11,
                      "instance_name 4": 14,
                      "instance_name 5": 17,
                      "instance_private_ip 1": 8,
                      "instance_private_ip 2": 10,
                      "instance_private_ip 3": 12,
                      "instance_private_ip 4": 15,
                      "instance_private_ip 5": 18,
                      "node_class 1": 3,
                      "node_id 1": 2,
                      "node_scheduling_eligibility 1": 5,
                      "node_status 1": 4
                    },
                    "renameByName": {
                      "Value #A": "Uptime",
                      "Value #B": "Allocs",
                      "Value #C": "CPU",
                      "Value #D": "Memory",
                      "Value #E": "Disk",
                      "instance": "Client",
                      "instance_name 1": "Instance",
                      "node_class": "Node class",
                      "node_class 1": "Node class",
                      "node_id": "Node ID",
                      "node_id 1": "Node ID",
                      "node_scheduling_eligibility": "Elegibility",
                      "node_scheduling_eligibility 1": "Eligibility",
                      "node_status": "Status",
                      "node_status 1": "Status"
                    }
                  }
                }
              ],
              "type": "table"
            },
            {
              "collapsed": false,
              "gridPos": {
                "h": 1,
                "w": 24,
                "x": 0,
                "y": 16
              },
              "id": 10,
              "panels": [],
              "title": "CPU",
              "type": "row"
            },
            {
              "datasource": {
                "type": "prometheus",
                "uid": "${DS_PROMETHEUS}"
              },
              "fieldConfig": {
                "defaults": {
                  "color": {
                    "mode": "palette-classic"
                  },
                  "custom": {
                    "axisCenteredZero": false,
                    "axisColorMode": "text",
                    "axisLabel": "",
                    "axisPlacement": "auto",
                    "barAlignment": 0,
                    "drawStyle": "line",
                    "fillOpacity": 100,
                    "gradientMode": "opacity",
                    "hideFrom": {
                      "legend": false,
                      "tooltip": false,
                      "viz": false
                    },
                    "lineInterpolation": "linear",
                    "lineStyle": {
                      "fill": "solid"
                    },
                    "lineWidth": 2,
                    "pointSize": 5,
                    "scaleDistribution": {
                      "type": "linear"
                    },
                    "showPoints": "auto",
                    "spanNulls": false,
                    "stacking": {
                      "group": "A",
                      "mode": "none"
                    },
                    "thresholdsStyle": {
                      "mode": "off"
                    }
                  },
                  "mappings": [],
                  "thresholds": {
                    "mode": "absolute",
                    "steps": [
                      {
                        "color": "green",
                        "value": null
                      },
                      {
                        "color": "red",
                        "value": 80
                      }
                    ]
                  },
                  "unit": "percentunit"
                },
                "overrides": []
              },
              "gridPos": {
                "h": 8,
                "w": 24,
                "x": 0,
                "y": 17
              },
              "id": 14,
              "options": {
                "legend": {
                  "calcs": [],
                  "displayMode": "list",
                  "placement": "bottom",
                  "showLegend": true
                },
                "tooltip": {
                  "mode": "single",
                  "sort": "none"
                }
              },
              "targets": [
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "expr": "sum by (namespace)(nomad_client_allocs_cpu_total_ticks{cluster=\"$cluster\"}) / sum by (namespace)(nomad_client_allocs_cpu_allocated{cluster=\"$cluster\"})",
                  "legendFormat": "__auto",
                  "range": true,
                  "refId": "A"
                }
              ],
              "title": "CPU Usage",
              "type": "timeseries"
            },
            {
              "collapsed": false,
              "gridPos": {
                "h": 1,
                "w": 24,
                "x": 0,
                "y": 25
              },
              "id": 12,
              "panels": [],
              "title": "Memory",
              "type": "row"
            },
            {
              "datasource": {
                "type": "prometheus",
                "uid": "${DS_PROMETHEUS}"
              },
              "fieldConfig": {
                "defaults": {
                  "color": {
                    "mode": "palette-classic"
                  },
                  "custom": {
                    "axisCenteredZero": false,
                    "axisColorMode": "text",
                    "axisLabel": "",
                    "axisPlacement": "auto",
                    "barAlignment": 0,
                    "drawStyle": "line",
                    "fillOpacity": 100,
                    "gradientMode": "opacity",
                    "hideFrom": {
                      "legend": false,
                      "tooltip": false,
                      "viz": false
                    },
                    "lineInterpolation": "linear",
                    "lineStyle": {
                      "fill": "solid"
                    },
                    "lineWidth": 2,
                    "pointSize": 5,
                    "scaleDistribution": {
                      "type": "linear"
                    },
                    "showPoints": "auto",
                    "spanNulls": false,
                    "stacking": {
                      "group": "A",
                      "mode": "none"
                    },
                    "thresholdsStyle": {
                      "mode": "off"
                    }
                  },
                  "mappings": [],
                  "thresholds": {
                    "mode": "absolute",
                    "steps": [
                      {
                        "color": "green",
                        "value": null
                      },
                      {
                        "color": "red",
                        "value": 80
                      }
                    ]
                  },
                  "unit": "percentunit"
                },
                "overrides": []
              },
              "gridPos": {
                "h": 8,
                "w": 24,
                "x": 0,
                "y": 26
              },
              "id": 17,
              "options": {
                "legend": {
                  "calcs": [],
                  "displayMode": "list",
                  "placement": "bottom",
                  "showLegend": true
                },
                "tooltip": {
                  "mode": "single",
                  "sort": "none"
                }
              },
              "targets": [
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "expr": "sum by (namespace)(nomad_client_allocs_memory_usage{cluster=\"$cluster\"}) / sum by (namespace)(nomad_client_allocs_memory_allocated{cluster=\"$cluster\"})",
                  "legendFormat": "__auto",
                  "range": true,
                  "refId": "A"
                }
              ],
              "title": "Memory Usage",
              "type": "timeseries"
            }
          ],
          "schemaVersion": 37,
          "style": "dark",
          "tags": [
            "nomad",
            "nomad-clients"
          ],
          "templating": {
            "list": [
              {
                "current": {
                  "selected": false,
                  "text": "Prometheus",
                  "value": "Prometheus"
                },
                "hide": 0,
                "includeAll": false,
                "label": "datasource",
                "multi": false,
                "name": "DS_PROMETHEUS",
                "options": [],
                "query": "prometheus",
                "refresh": 1,
                "regex": "",
                "skipUrlSync": false,
                "type": "datasource"
              },
              {
                "current": {},
                "datasource": {
                  "type": "prometheus",
                  "uid": "${DS_PROMETHEUS}"
                },
                "definition": "label_values(nomad_client_uptime, cluster)",
                "hide": 0,
                "includeAll": false,
                "label": "Cluster",
                "multi": false,
                "name": "cluster",
                "options": [],
                "query": {
                  "query": "label_values(nomad_client_uptime, cluster)",
                  "refId": "StandardVariableQuery"
                },
                "refresh": 1,
                "regex": "",
                "skipUrlSync": false,
                "sort": 0,
                "type": "query"
              }
            ]
          },
          "time": {
            "from": "now-6h",
            "to": "now"
          },
          "timepicker": {},
          "timezone": "",
          "title": "Clients",
          "uid": "Y72kP0G4z",
          "version": 1,
          "weekStart": ""
        }
        EOF
        destination     = "local/grafana/provisioning/dashboards/nomad/clients.json"
        left_delimiter  = "[["
        right_delimiter = "]]"
      }
      template {
        data            = <<EOF
        {
          "__inputs": [
            {
              "name": "DS_PROMETHEUS",
              "label": "Prometheus",
              "description": "",
              "type": "datasource",
              "pluginId": "prometheus",
              "pluginName": "Prometheus"
            }
          ],
          "__elements": {},
          "__requires": [
            {
              "type": "grafana",
              "id": "grafana",
              "name": "Grafana",
              "version": "9.1.4"
            },
            {
              "type": "datasource",
              "id": "prometheus",
              "name": "Prometheus",
              "version": "1.0.0"
            },
            {
              "type": "panel",
              "id": "table",
              "name": "Table",
              "version": ""
            },
            {
              "type": "panel",
              "id": "timeseries",
              "name": "Time series",
              "version": ""
            }
          ],
          "annotations": {
            "list": [
              {
                "builtIn": 1,
                "datasource": {
                  "type": "grafana",
                  "uid": "-- Grafana --"
                },
                "enable": true,
                "hide": true,
                "iconColor": "rgba(0, 211, 255, 1)",
                "name": "Annotations & Alerts",
                "target": {
                  "limit": 100,
                  "matchAny": false,
                  "tags": [],
                  "type": "dashboard"
                },
                "type": "dashboard"
              }
            ]
          },
          "editable": true,
          "fiscalYearStartMonth": 0,
          "graphTooltip": 0,
          "id": null,
          "links": [],
          "liveNow": false,
          "panels": [
            {
              "collapsed": false,
              "gridPos": {
                "h": 1,
                "w": 24,
                "x": 0,
                "y": 0
              },
              "id": 2,
              "panels": [],
              "title": "Memory",
              "type": "row"
            },
            {
              "datasource": {
                "type": "prometheus",
                "uid": "${DS_PROMETHEUS}"
              },
              "fieldConfig": {
                "defaults": {
                  "color": {
                    "mode": "palette-classic"
                  },
                  "custom": {
                    "axisCenteredZero": false,
                    "axisColorMode": "text",
                    "axisLabel": "",
                    "axisPlacement": "auto",
                    "barAlignment": 0,
                    "drawStyle": "line",
                    "fillOpacity": 0,
                    "gradientMode": "none",
                    "hideFrom": {
                      "legend": false,
                      "tooltip": false,
                      "viz": false
                    },
                    "lineInterpolation": "linear",
                    "lineWidth": 1,
                    "pointSize": 5,
                    "scaleDistribution": {
                      "type": "linear"
                    },
                    "showPoints": "auto",
                    "spanNulls": false,
                    "stacking": {
                      "group": "A",
                      "mode": "none"
                    },
                    "thresholdsStyle": {
                      "mode": "off"
                    }
                  },
                  "mappings": [],
                  "thresholds": {
                    "mode": "absolute",
                    "steps": [
                      {
                        "color": "green",
                        "value": null
                      },
                      {
                        "color": "red",
                        "value": 80
                      }
                    ]
                  },
                  "unit": "bytes"
                },
                "overrides": []
              },
              "gridPos": {
                "h": 7,
                "w": 9,
                "x": 0,
                "y": 1
              },
              "id": 8,
              "options": {
                "legend": {
                  "calcs": [],
                  "displayMode": "list",
                  "placement": "bottom",
                  "showLegend": true
                },
                "tooltip": {
                  "mode": "single",
                  "sort": "none"
                }
              },
              "targets": [
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "expr": "sum by (hostname) (nomad_runtime_alloc_bytes{cluster=\"$cluster\"})",
                  "legendFormat": "__auto",
                  "range": true,
                  "refId": "A"
                }
              ],
              "title": "Memory utilization",
              "type": "timeseries"
            },
            {
              "datasource": {
                "type": "prometheus",
                "uid": "${DS_PROMETHEUS}"
              },
              "description": "Number of objects on the heap. General memory pressure indicator",
              "fieldConfig": {
                "defaults": {
                  "color": {
                    "mode": "palette-classic"
                  },
                  "custom": {
                    "axisCenteredZero": false,
                    "axisColorMode": "text",
                    "axisLabel": "",
                    "axisPlacement": "auto",
                    "barAlignment": 0,
                    "drawStyle": "line",
                    "fillOpacity": 0,
                    "gradientMode": "none",
                    "hideFrom": {
                      "legend": false,
                      "tooltip": false,
                      "viz": false
                    },
                    "lineInterpolation": "linear",
                    "lineWidth": 1,
                    "pointSize": 5,
                    "scaleDistribution": {
                      "type": "linear"
                    },
                    "showPoints": "auto",
                    "spanNulls": false,
                    "stacking": {
                      "group": "A",
                      "mode": "none"
                    },
                    "thresholdsStyle": {
                      "mode": "off"
                    }
                  },
                  "mappings": [],
                  "thresholds": {
                    "mode": "absolute",
                    "steps": [
                      {
                        "color": "green",
                        "value": null
                      },
                      {
                        "color": "red",
                        "value": 80
                      }
                    ]
                  },
                  "unit": "short"
                },
                "overrides": []
              },
              "gridPos": {
                "h": 7,
                "w": 8,
                "x": 9,
                "y": 1
              },
              "id": 10,
              "options": {
                "legend": {
                  "calcs": [],
                  "displayMode": "list",
                  "placement": "bottom",
                  "showLegend": true
                },
                "tooltip": {
                  "mode": "single",
                  "sort": "none"
                }
              },
              "targets": [
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "expr": "sum by (hostname) (nomad_runtime_heap_objects{cluster=\"$cluster\"})",
                  "legendFormat": "__auto",
                  "range": true,
                  "refId": "A"
                }
              ],
              "title": "Count of objects in heap",
              "type": "timeseries"
            },
            {
              "datasource": {
                "type": "prometheus",
                "uid": "${DS_PROMETHEUS}"
              },
              "description": "Number of goroutines and general load pressure indicator",
              "fieldConfig": {
                "defaults": {
                  "color": {
                    "mode": "palette-classic"
                  },
                  "custom": {
                    "axisCenteredZero": false,
                    "axisColorMode": "text",
                    "axisLabel": "",
                    "axisPlacement": "auto",
                    "barAlignment": 0,
                    "drawStyle": "line",
                    "fillOpacity": 40,
                    "gradientMode": "hue",
                    "hideFrom": {
                      "legend": false,
                      "tooltip": false,
                      "viz": false
                    },
                    "lineInterpolation": "linear",
                    "lineWidth": 1,
                    "pointSize": 5,
                    "scaleDistribution": {
                      "type": "linear"
                    },
                    "showPoints": "auto",
                    "spanNulls": false,
                    "stacking": {
                      "group": "A",
                      "mode": "none"
                    },
                    "thresholdsStyle": {
                      "mode": "off"
                    }
                  },
                  "mappings": [],
                  "thresholds": {
                    "mode": "absolute",
                    "steps": [
                      {
                        "color": "green",
                        "value": null
                      },
                      {
                        "color": "red",
                        "value": 80
                      }
                    ]
                  },
                  "unit": "short"
                },
                "overrides": []
              },
              "gridPos": {
                "h": 7,
                "w": 7,
                "x": 17,
                "y": 1
              },
              "id": 16,
              "options": {
                "legend": {
                  "calcs": [],
                  "displayMode": "list",
                  "placement": "bottom",
                  "showLegend": true
                },
                "tooltip": {
                  "mode": "single",
                  "sort": "none"
                }
              },
              "targets": [
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "expr": "sum by (hostname) (nomad_runtime_num_goroutines{cluster=\"$cluster\"})",
                  "legendFormat": "__auto",
                  "range": true,
                  "refId": "A"
                }
              ],
              "title": "Goroutines",
              "type": "timeseries"
            },
            {
              "collapsed": false,
              "gridPos": {
                "h": 1,
                "w": 24,
                "x": 0,
                "y": 8
              },
              "id": 12,
              "panels": [],
              "title": "Raft",
              "type": "row"
            },
            {
              "datasource": {
                "type": "prometheus",
                "uid": "${DS_PROMETHEUS}"
              },
              "description": "Time since last contact to leader. General indicator of Raft latency",
              "fieldConfig": {
                "defaults": {
                  "color": {
                    "mode": "palette-classic"
                  },
                  "custom": {
                    "axisCenteredZero": false,
                    "axisColorMode": "text",
                    "axisLabel": "",
                    "axisPlacement": "auto",
                    "barAlignment": 0,
                    "drawStyle": "line",
                    "fillOpacity": 34,
                    "gradientMode": "opacity",
                    "hideFrom": {
                      "legend": false,
                      "tooltip": false,
                      "viz": false
                    },
                    "lineInterpolation": "linear",
                    "lineWidth": 1,
                    "pointSize": 5,
                    "scaleDistribution": {
                      "type": "linear"
                    },
                    "showPoints": "auto",
                    "spanNulls": false,
                    "stacking": {
                      "group": "A",
                      "mode": "none"
                    },
                    "thresholdsStyle": {
                      "mode": "off"
                    }
                  },
                  "mappings": [],
                  "thresholds": {
                    "mode": "absolute",
                    "steps": [
                      {
                        "color": "green",
                        "value": null
                      },
                      {
                        "color": "red",
                        "value": 80
                      }
                    ]
                  },
                  "unit": "ms"
                },
                "overrides": []
              },
              "gridPos": {
                "h": 8,
                "w": 12,
                "x": 0,
                "y": 9
              },
              "id": 6,
              "options": {
                "legend": {
                  "calcs": [],
                  "displayMode": "list",
                  "placement": "bottom",
                  "showLegend": true
                },
                "tooltip": {
                  "mode": "single",
                  "sort": "none"
                }
              },
              "targets": [
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "expr": "sum by (hostname) (nomad_raft_leader_lastContact{cluster=\"$cluster\",quantile=\"0.99\"})",
                  "legendFormat": "p99 - {{hostname}}",
                  "range": true,
                  "refId": "A"
                }
              ],
              "title": "Raft Last Contact",
              "type": "timeseries"
            },
            {
              "datasource": {
                "type": "prometheus",
                "uid": "${DS_PROMETHEUS}"
              },
              "description": "Number of Raft transactions",
              "fieldConfig": {
                "defaults": {
                  "color": {
                    "mode": "palette-classic"
                  },
                  "custom": {
                    "axisCenteredZero": false,
                    "axisColorMode": "text",
                    "axisLabel": "",
                    "axisPlacement": "auto",
                    "barAlignment": 0,
                    "drawStyle": "line",
                    "fillOpacity": 0,
                    "gradientMode": "none",
                    "hideFrom": {
                      "legend": false,
                      "tooltip": false,
                      "viz": false
                    },
                    "lineInterpolation": "linear",
                    "lineWidth": 1,
                    "pointSize": 5,
                    "scaleDistribution": {
                      "type": "linear"
                    },
                    "showPoints": "auto",
                    "spanNulls": false,
                    "stacking": {
                      "group": "A",
                      "mode": "none"
                    },
                    "thresholdsStyle": {
                      "mode": "off"
                    }
                  },
                  "mappings": [],
                  "thresholds": {
                    "mode": "absolute",
                    "steps": [
                      {
                        "color": "green",
                        "value": null
                      },
                      {
                        "color": "red",
                        "value": 80
                      }
                    ]
                  },
                  "unit": "short"
                },
                "overrides": []
              },
              "gridPos": {
                "h": 8,
                "w": 12,
                "x": 12,
                "y": 9
              },
              "id": 20,
              "options": {
                "legend": {
                  "calcs": [],
                  "displayMode": "list",
                  "placement": "bottom",
                  "showLegend": true
                },
                "tooltip": {
                  "mode": "single",
                  "sort": "none"
                }
              },
              "targets": [
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "expr": "sum by (hostname) (rate(nomad_raft_appliedIndex{cluster=\"$cluster\"}[1m]))",
                  "legendFormat": "__auto",
                  "range": true,
                  "refId": "A"
                }
              ],
              "title": "Raft Transactions",
              "type": "timeseries"
            },
            {
              "datasource": {
                "type": "prometheus",
                "uid": "${DS_PROMETHEUS}"
              },
              "description": "Time elapsed to write log, mark in flight, and start replication",
              "fieldConfig": {
                "defaults": {
                  "color": {
                    "mode": "palette-classic"
                  },
                  "custom": {
                    "axisCenteredZero": false,
                    "axisColorMode": "text",
                    "axisLabel": "",
                    "axisPlacement": "auto",
                    "barAlignment": 0,
                    "drawStyle": "line",
                    "fillOpacity": 30,
                    "gradientMode": "opacity",
                    "hideFrom": {
                      "legend": false,
                      "tooltip": false,
                      "viz": false
                    },
                    "lineInterpolation": "smooth",
                    "lineWidth": 1,
                    "pointSize": 5,
                    "scaleDistribution": {
                      "type": "linear"
                    },
                    "showPoints": "never",
                    "spanNulls": false,
                    "stacking": {
                      "group": "A",
                      "mode": "none"
                    },
                    "thresholdsStyle": {
                      "mode": "line"
                    }
                  },
                  "mappings": [],
                  "thresholds": {
                    "mode": "absolute",
                    "steps": [
                      {
                        "color": "text",
                        "value": null
                      }
                    ]
                  },
                  "unit": "ms"
                },
                "overrides": [
                  {
                    "matcher": {
                      "id": "byName",
                      "options": "Logs"
                    },
                    "properties": [
                      {
                        "id": "unit",
                        "value": "short"
                      }
                    ]
                  },
                  {
                    "matcher": {
                      "id": "byName",
                      "options": "Time"
                    },
                    "properties": [
                      {
                        "id": "thresholds",
                        "value": {
                          "mode": "absolute",
                          "steps": [
                            {
                              "color": "green",
                              "value": null
                            },
                            {
                              "color": "light-orange",
                              "value": 200
                            },
                            {
                              "color": "red",
                              "value": 500
                            }
                          ]
                        }
                      }
                    ]
                  }
                ]
              },
              "gridPos": {
                "h": 8,
                "w": 9,
                "x": 0,
                "y": 17
              },
              "id": 22,
              "options": {
                "legend": {
                  "calcs": [],
                  "displayMode": "table",
                  "placement": "right",
                  "showLegend": true
                },
                "tooltip": {
                  "mode": "multi",
                  "sort": "none"
                }
              },
              "pluginVersion": "8.1.0",
              "targets": [
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "exemplar": true,
                  "expr": "nomad_raft_leader_dispatchLog{cluster=\"$cluster\",quantile=\"0.9\"}",
                  "hide": false,
                  "interval": "",
                  "intervalFactor": 1,
                  "legendFormat": "Time",
                  "range": true,
                  "refId": "C"
                },
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "exemplar": true,
                  "expr": "increase(nomad_raft_leader_dispatchNumLogs{cluster=\"$cluster\"}[$__rate_interval])",
                  "hide": false,
                  "interval": "",
                  "legendFormat": "Logs",
                  "range": true,
                  "refId": "A"
                }
              ],
              "title": "Raft Dispatch Log",
              "type": "timeseries"
            },
            {
              "datasource": {
                "type": "prometheus",
                "uid": "${DS_PROMETHEUS}"
              },
              "description": "Time elapsed to broadcast gossip messages",
              "fieldConfig": {
                "defaults": {
                  "color": {
                    "mode": "palette-classic"
                  },
                  "custom": {
                    "axisCenteredZero": false,
                    "axisColorMode": "text",
                    "axisLabel": "",
                    "axisPlacement": "auto",
                    "barAlignment": 0,
                    "drawStyle": "line",
                    "fillOpacity": 49,
                    "gradientMode": "hue",
                    "hideFrom": {
                      "legend": false,
                      "tooltip": false,
                      "viz": false
                    },
                    "lineInterpolation": "linear",
                    "lineWidth": 1,
                    "pointSize": 5,
                    "scaleDistribution": {
                      "type": "linear"
                    },
                    "showPoints": "auto",
                    "spanNulls": false,
                    "stacking": {
                      "group": "A",
                      "mode": "none"
                    },
                    "thresholdsStyle": {
                      "mode": "off"
                    }
                  },
                  "mappings": [],
                  "thresholds": {
                    "mode": "absolute",
                    "steps": [
                      {
                        "color": "green",
                        "value": null
                      },
                      {
                        "color": "red",
                        "value": 80
                      }
                    ]
                  },
                  "unit": "ns"
                },
                "overrides": []
              },
              "gridPos": {
                "h": 8,
                "w": 7,
                "x": 9,
                "y": 17
              },
              "id": 46,
              "options": {
                "legend": {
                  "calcs": [],
                  "displayMode": "list",
                  "placement": "bottom",
                  "showLegend": true
                },
                "tooltip": {
                  "mode": "single",
                  "sort": "none"
                }
              },
              "targets": [
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "expr": "sum by (hostname)  (rate(nomad_memberlist_gossip_sum{cluster=\"$cluster\"}[5m]))\n/\n  sum by (hostname) (rate(nomad_memberlist_gossip_count{cluster=\"$cluster\"}[5m]))",
                  "legendFormat": "__auto",
                  "range": true,
                  "refId": "A"
                }
              ],
              "title": "Memberlist Gossip",
              "type": "timeseries"
            },
            {
              "datasource": {
                "type": "prometheus",
                "uid": "${DS_PROMETHEUS}"
              },
              "description": "Number of Raft transactions - general indicator of the write load on the servers.",
              "fieldConfig": {
                "defaults": {
                  "color": {
                    "mode": "palette-classic"
                  },
                  "custom": {
                    "axisCenteredZero": false,
                    "axisColorMode": "text",
                    "axisLabel": "",
                    "axisPlacement": "auto",
                    "barAlignment": 0,
                    "drawStyle": "line",
                    "fillOpacity": 30,
                    "gradientMode": "opacity",
                    "hideFrom": {
                      "legend": false,
                      "tooltip": false,
                      "viz": false
                    },
                    "lineInterpolation": "stepBefore",
                    "lineWidth": 1,
                    "pointSize": 5,
                    "scaleDistribution": {
                      "type": "linear"
                    },
                    "showPoints": "never",
                    "spanNulls": false,
                    "stacking": {
                      "group": "A",
                      "mode": "none"
                    },
                    "thresholdsStyle": {
                      "mode": "off"
                    }
                  },
                  "decimals": 0,
                  "mappings": [],
                  "thresholds": {
                    "mode": "absolute",
                    "steps": [
                      {
                        "color": "green",
                        "value": null
                      }
                    ]
                  },
                  "unit": "none"
                },
                "overrides": []
              },
              "gridPos": {
                "h": 8,
                "w": 8,
                "x": 16,
                "y": 17
              },
              "id": 26,
              "options": {
                "legend": {
                  "calcs": [
                    "mean",
                    "max",
                    "lastNotNull"
                  ],
                  "displayMode": "list",
                  "placement": "bottom",
                  "showLegend": true
                },
                "tooltip": {
                  "mode": "multi",
                  "sort": "none"
                }
              },
              "pluginVersion": "8.1.0",
              "targets": [
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "exemplar": true,
                  "expr": "increase(nomad_raft_apply{cluster=\"$cluster\"}[$__rate_interval])",
                  "interval": "",
                  "legendFormat": "{{ instance }}",
                  "range": true,
                  "refId": "A"
                }
              ],
              "title": "Raft Apply Count",
              "type": "timeseries"
            },
            {
              "datasource": {
                "type": "prometheus",
                "uid": "${DS_PROMETHEUS}"
              },
              "description": "Time difference between when a message was first passed into Raft and when the resulting commit took place on the leader",
              "fieldConfig": {
                "defaults": {
                  "color": {
                    "mode": "palette-classic"
                  },
                  "custom": {
                    "axisCenteredZero": false,
                    "axisColorMode": "text",
                    "axisLabel": "",
                    "axisPlacement": "auto",
                    "barAlignment": 0,
                    "drawStyle": "line",
                    "fillOpacity": 30,
                    "gradientMode": "opacity",
                    "hideFrom": {
                      "legend": false,
                      "tooltip": false,
                      "viz": false
                    },
                    "lineInterpolation": "smooth",
                    "lineWidth": 1,
                    "pointSize": 5,
                    "scaleDistribution": {
                      "type": "linear"
                    },
                    "showPoints": "never",
                    "spanNulls": true,
                    "stacking": {
                      "group": "A",
                      "mode": "none"
                    },
                    "thresholdsStyle": {
                      "mode": "line"
                    }
                  },
                  "mappings": [],
                  "thresholds": {
                    "mode": "absolute",
                    "steps": [
                      {
                        "color": "green"
                      },
                      {
                        "color": "yellow",
                        "value": 100
                      },
                      {
                        "color": "red",
                        "value": 500
                      }
                    ]
                  },
                  "unit": "ms"
                },
                "overrides": []
              },
              "gridPos": {
                "h": 8,
                "w": 8,
                "x": 0,
                "y": 25
              },
              "id": 24,
              "options": {
                "legend": {
                  "calcs": [
                    "mean",
                    "max",
                    "lastNotNull"
                  ],
                  "displayMode": "list",
                  "placement": "bottom",
                  "showLegend": true
                },
                "tooltip": {
                  "mode": "multi",
                  "sort": "none"
                }
              },
              "pluginVersion": "8.1.0",
              "targets": [
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "exemplar": true,
                  "expr": "nomad_raft_commitTime{cluster=\"$cluster\",quantile=\"0.9\"}",
                  "interval": "",
                  "intervalFactor": 1,
                  "legendFormat": "{{ instance }}",
                  "range": true,
                  "refId": "A"
                }
              ],
              "title": "Raft Commit Time",
              "type": "timeseries"
            },
            {
              "datasource": {
                "type": "prometheus",
                "uid": "${DS_PROMETHEUS}"
              },
              "description": "The time it takes for a Raft transaction to be replicated to a quorum of followers",
              "fieldConfig": {
                "defaults": {
                  "color": {
                    "mode": "palette-classic"
                  },
                  "custom": {
                    "axisCenteredZero": false,
                    "axisColorMode": "text",
                    "axisLabel": "",
                    "axisPlacement": "auto",
                    "barAlignment": 0,
                    "drawStyle": "line",
                    "fillOpacity": 30,
                    "gradientMode": "opacity",
                    "hideFrom": {
                      "legend": false,
                      "tooltip": false,
                      "viz": false
                    },
                    "lineInterpolation": "smooth",
                    "lineWidth": 1,
                    "pointSize": 5,
                    "scaleDistribution": {
                      "type": "linear"
                    },
                    "showPoints": "never",
                    "spanNulls": false,
                    "stacking": {
                      "group": "A",
                      "mode": "none"
                    },
                    "thresholdsStyle": {
                      "mode": "line"
                    }
                  },
                  "mappings": [],
                  "thresholds": {
                    "mode": "absolute",
                    "steps": [
                      {
                        "color": "green"
                      },
                      {
                        "color": "yellow",
                        "value": 100
                      },
                      {
                        "color": "red",
                        "value": 500
                      }
                    ]
                  },
                  "unit": "ms"
                },
                "overrides": []
              },
              "gridPos": {
                "h": 8,
                "w": 8,
                "x": 8,
                "y": 25
              },
              "id": 28,
              "options": {
                "legend": {
                  "calcs": [
                    "mean",
                    "max",
                    "lastNotNull"
                  ],
                  "displayMode": "table",
                  "placement": "bottom",
                  "showLegend": true
                },
                "tooltip": {
                  "mode": "multi",
                  "sort": "none"
                }
              },
              "pluginVersion": "8.1.0",
              "targets": [
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "exemplar": true,
                  "expr": "nomad_raft_rpc_appendEntries{cluster=\"$cluster\",quantile=\"0.9\"}",
                  "interval": "",
                  "intervalFactor": 1,
                  "legendFormat": "{{ instance }}",
                  "range": true,
                  "refId": "A"
                }
              ],
              "title": "Raft Append Entries",
              "type": "timeseries"
            },
            {
              "datasource": {
                "type": "prometheus",
                "uid": "${DS_PROMETHEUS}"
              },
              "description": "Time it takes for a server to apply Raft entries to the internal state machine.",
              "fieldConfig": {
                "defaults": {
                  "color": {
                    "mode": "palette-classic"
                  },
                  "custom": {
                    "axisCenteredZero": false,
                    "axisColorMode": "text",
                    "axisLabel": "",
                    "axisPlacement": "auto",
                    "barAlignment": 0,
                    "drawStyle": "line",
                    "fillOpacity": 30,
                    "gradientMode": "opacity",
                    "hideFrom": {
                      "legend": false,
                      "tooltip": false,
                      "viz": false
                    },
                    "lineInterpolation": "smooth",
                    "lineWidth": 1,
                    "pointSize": 5,
                    "scaleDistribution": {
                      "type": "linear"
                    },
                    "showPoints": "never",
                    "spanNulls": true,
                    "stacking": {
                      "group": "A",
                      "mode": "none"
                    },
                    "thresholdsStyle": {
                      "mode": "line"
                    }
                  },
                  "mappings": [],
                  "thresholds": {
                    "mode": "absolute",
                    "steps": [
                      {
                        "color": "green"
                      },
                      {
                        "color": "yellow",
                        "value": 100
                      },
                      {
                        "color": "red",
                        "value": 500
                      }
                    ]
                  },
                  "unit": "ms"
                },
                "overrides": []
              },
              "gridPos": {
                "h": 8,
                "w": 8,
                "x": 16,
                "y": 25
              },
              "id": 30,
              "options": {
                "legend": {
                  "calcs": [
                    "mean",
                    "max",
                    "lastNotNull"
                  ],
                  "displayMode": "table",
                  "placement": "bottom",
                  "showLegend": true
                },
                "tooltip": {
                  "mode": "multi",
                  "sort": "none"
                }
              },
              "pluginVersion": "8.1.0",
              "targets": [
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "exemplar": true,
                  "expr": "nomad_raft_fsm_apply{cluster=\"$cluster\",quantile=\"0.9\"}",
                  "interval": "",
                  "intervalFactor": 1,
                  "legendFormat": "{{ instance }}",
                  "range": true,
                  "refId": "A"
                }
              ],
              "title": "Raft FSM apply",
              "type": "timeseries"
            },
            {
              "collapsed": false,
              "gridPos": {
                "h": 1,
                "w": 24,
                "x": 0,
                "y": 33
              },
              "id": 40,
              "panels": [],
              "title": "RPC",
              "type": "row"
            },
            {
              "datasource": {
                "type": "prometheus",
                "uid": "${DS_PROMETHEUS}"
              },
              "description": "Number of RPC requests being handled",
              "fieldConfig": {
                "defaults": {
                  "color": {
                    "mode": "palette-classic"
                  },
                  "custom": {
                    "axisCenteredZero": false,
                    "axisColorMode": "text",
                    "axisLabel": "",
                    "axisPlacement": "auto",
                    "barAlignment": 0,
                    "drawStyle": "line",
                    "fillOpacity": 50,
                    "gradientMode": "hue",
                    "hideFrom": {
                      "legend": false,
                      "tooltip": false,
                      "viz": false
                    },
                    "lineInterpolation": "linear",
                    "lineWidth": 1,
                    "pointSize": 5,
                    "scaleDistribution": {
                      "type": "linear"
                    },
                    "showPoints": "auto",
                    "spanNulls": false,
                    "stacking": {
                      "group": "A",
                      "mode": "none"
                    },
                    "thresholdsStyle": {
                      "mode": "off"
                    }
                  },
                  "mappings": [],
                  "thresholds": {
                    "mode": "absolute",
                    "steps": [
                      {
                        "color": "green"
                      },
                      {
                        "color": "red",
                        "value": 80
                      }
                    ]
                  }
                },
                "overrides": []
              },
              "gridPos": {
                "h": 8,
                "w": 8,
                "x": 0,
                "y": 34
              },
              "id": 42,
              "options": {
                "legend": {
                  "calcs": [],
                  "displayMode": "list",
                  "placement": "bottom",
                  "showLegend": true
                },
                "tooltip": {
                  "mode": "single",
                  "sort": "none"
                }
              },
              "targets": [
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "expr": "sum by (hostname) (rate(nomad_nomad_rpc_request{cluster=\"$cluster\"}[1m]))",
                  "legendFormat": "__auto",
                  "range": true,
                  "refId": "A"
                }
              ],
              "title": "RPC Requests",
              "type": "timeseries"
            },
            {
              "datasource": {
                "type": "prometheus",
                "uid": "${DS_PROMETHEUS}"
              },
              "description": "Number of RPC queries",
              "fieldConfig": {
                "defaults": {
                  "color": {
                    "mode": "palette-classic"
                  },
                  "custom": {
                    "axisCenteredZero": false,
                    "axisColorMode": "text",
                    "axisLabel": "",
                    "axisPlacement": "auto",
                    "barAlignment": 0,
                    "drawStyle": "line",
                    "fillOpacity": 50,
                    "gradientMode": "hue",
                    "hideFrom": {
                      "legend": false,
                      "tooltip": false,
                      "viz": false
                    },
                    "lineInterpolation": "linear",
                    "lineWidth": 1,
                    "pointSize": 5,
                    "scaleDistribution": {
                      "type": "linear"
                    },
                    "showPoints": "auto",
                    "spanNulls": false,
                    "stacking": {
                      "group": "A",
                      "mode": "none"
                    },
                    "thresholdsStyle": {
                      "mode": "off"
                    }
                  },
                  "mappings": [],
                  "thresholds": {
                    "mode": "absolute",
                    "steps": [
                      {
                        "color": "green"
                      },
                      {
                        "color": "red",
                        "value": 80
                      }
                    ]
                  }
                },
                "overrides": []
              },
              "gridPos": {
                "h": 8,
                "w": 8,
                "x": 8,
                "y": 34
              },
              "id": 43,
              "options": {
                "legend": {
                  "calcs": [],
                  "displayMode": "list",
                  "placement": "bottom",
                  "showLegend": true
                },
                "tooltip": {
                  "mode": "single",
                  "sort": "none"
                }
              },
              "targets": [
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "expr": "sum by (hostname) (rate(nomad_nomad_rpc_query{cluster=\"$cluster\"}[1m]))",
                  "legendFormat": "__auto",
                  "range": true,
                  "refId": "A"
                }
              ],
              "title": "RPC Queries",
              "type": "timeseries"
            },
            {
              "datasource": {
                "type": "prometheus",
                "uid": "${DS_PROMETHEUS}"
              },
              "description": "Number of RPC requests being handled that result in an error",
              "fieldConfig": {
                "defaults": {
                  "color": {
                    "mode": "palette-classic"
                  },
                  "custom": {
                    "axisCenteredZero": false,
                    "axisColorMode": "text",
                    "axisLabel": "",
                    "axisPlacement": "auto",
                    "barAlignment": 0,
                    "drawStyle": "line",
                    "fillOpacity": 50,
                    "gradientMode": "hue",
                    "hideFrom": {
                      "legend": false,
                      "tooltip": false,
                      "viz": false
                    },
                    "lineInterpolation": "linear",
                    "lineWidth": 1,
                    "pointSize": 5,
                    "scaleDistribution": {
                      "type": "linear"
                    },
                    "showPoints": "auto",
                    "spanNulls": false,
                    "stacking": {
                      "group": "A",
                      "mode": "none"
                    },
                    "thresholdsStyle": {
                      "mode": "off"
                    }
                  },
                  "mappings": [],
                  "thresholds": {
                    "mode": "absolute",
                    "steps": [
                      {
                        "color": "green"
                      },
                      {
                        "color": "red",
                        "value": 80
                      }
                    ]
                  }
                },
                "overrides": []
              },
              "gridPos": {
                "h": 8,
                "w": 8,
                "x": 16,
                "y": 34
              },
              "id": 44,
              "options": {
                "legend": {
                  "calcs": [],
                  "displayMode": "list",
                  "placement": "bottom",
                  "showLegend": true
                },
                "tooltip": {
                  "mode": "single",
                  "sort": "none"
                }
              },
              "targets": [
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "expr": "sum by (hostname) (rate(nomad_nomad_rpc_request_error{cluster=\"$cluster\"}[1m]))",
                  "legendFormat": "__auto",
                  "range": true,
                  "refId": "A"
                }
              ],
              "title": "RPC Errors",
              "type": "timeseries"
            },
            {
              "collapsed": false,
              "gridPos": {
                "h": 1,
                "w": 24,
                "x": 0,
                "y": 42
              },
              "id": 14,
              "panels": [],
              "title": "Evaluations",
              "type": "row"
            },
            {
              "datasource": {
                "type": "prometheus",
                "uid": "${DS_PROMETHEUS}"
              },
              "fieldConfig": {
                "defaults": {
                  "color": {
                    "mode": "palette-classic"
                  },
                  "custom": {
                    "axisCenteredZero": false,
                    "axisColorMode": "text",
                    "axisLabel": "",
                    "axisPlacement": "auto",
                    "barAlignment": 0,
                    "drawStyle": "line",
                    "fillOpacity": 0,
                    "gradientMode": "none",
                    "hideFrom": {
                      "legend": false,
                      "tooltip": false,
                      "viz": false
                    },
                    "lineInterpolation": "linear",
                    "lineWidth": 1,
                    "pointSize": 5,
                    "scaleDistribution": {
                      "type": "linear"
                    },
                    "showPoints": "auto",
                    "spanNulls": false,
                    "stacking": {
                      "group": "A",
                      "mode": "none"
                    },
                    "thresholdsStyle": {
                      "mode": "off"
                    }
                  },
                  "mappings": [],
                  "thresholds": {
                    "mode": "absolute",
                    "steps": [
                      {
                        "color": "green"
                      },
                      {
                        "color": "red",
                        "value": 80
                      }
                    ]
                  }
                },
                "overrides": []
              },
              "gridPos": {
                "h": 9,
                "w": 24,
                "x": 0,
                "y": 43
              },
              "id": 18,
              "options": {
                "legend": {
                  "calcs": [],
                  "displayMode": "list",
                  "placement": "bottom",
                  "showLegend": true
                },
                "tooltip": {
                  "mode": "single",
                  "sort": "none"
                }
              },
              "targets": [
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "expr": "sum by (cluster) (nomad_nomad_broker_total_blocked{cluster=\"$cluster\"})",
                  "legendFormat": "Blocked",
                  "range": true,
                  "refId": "A"
                },
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "expr": "sum by (cluster) (nomad_nomad_broker_total_ready{cluster=\"$cluster\"})",
                  "hide": false,
                  "legendFormat": "Ready",
                  "range": true,
                  "refId": "B"
                },
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "expr": "sum by (cluster) (nomad_nomad_broker_total_unacked{cluster=\"$cluster\"})",
                  "hide": false,
                  "legendFormat": "Pending",
                  "range": true,
                  "refId": "C"
                }
              ],
              "title": "Evaluations",
              "type": "timeseries"
            },
            {
              "collapsed": false,
              "gridPos": {
                "h": 1,
                "w": 24,
                "x": 0,
                "y": 52
              },
              "id": 34,
              "panels": [],
              "title": "Vault",
              "type": "row"
            },
            {
              "datasource": {
                "type": "prometheus",
                "uid": "${DS_PROMETHEUS}"
              },
              "description": "Time to live for Vault token",
              "fieldConfig": {
                "defaults": {
                  "color": {
                    "mode": "thresholds"
                  },
                  "custom": {
                    "align": "auto",
                    "displayMode": "auto",
                    "inspect": false
                  },
                  "mappings": [],
                  "thresholds": {
                    "mode": "absolute",
                    "steps": [
                      {
                        "color": "red"
                      },
                      {
                        "color": "#EAB839",
                        "value": 172800010
                      },
                      {
                        "color": "green",
                        "value": 345600000
                      }
                    ]
                  },
                  "unit": "ms"
                },
                "overrides": [
                  {
                    "matcher": {
                      "id": "byName",
                      "options": "TTL"
                    },
                    "properties": [
                      {
                        "id": "custom.displayMode",
                        "value": "color-background"
                      },
                      {
                        "id": "color",
                        "value": {
                          "mode": "thresholds"
                        }
                      }
                    ]
                  },
                  {
                    "matcher": {
                      "id": "byName",
                      "options": "hostname"
                    },
                    "properties": [
                      {
                        "id": "custom.width",
                        "value": 311
                      }
                    ]
                  }
                ]
              },
              "gridPos": {
                "h": 5,
                "w": 8,
                "x": 0,
                "y": 53
              },
              "id": 32,
              "options": {
                "footer": {
                  "fields": "",
                  "reducer": [
                    "sum"
                  ],
                  "show": false
                },
                "showHeader": true,
                "sortBy": []
              },
              "pluginVersion": "9.1.4",
              "targets": [
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "exemplar": false,
                  "expr": "nomad_nomad_vault_token_ttl{cluster=\"$cluster\"}",
                  "format": "table",
                  "instant": true,
                  "interval": "",
                  "legendFormat": "ttl",
                  "refId": "A"
                }
              ],
              "title": "Server token TTL",
              "transformations": [
                {
                  "id": "organize",
                  "options": {
                    "excludeByName": {
                      "Time": true,
                      "__name__": true,
                      "cluster": true,
                      "env": true,
                      "instance": true,
                      "instance_name": true,
                      "instance_private_ip": true,
                      "job": true,
                      "role": true,
                      "service": true
                    },
                    "indexByName": {},
                    "renameByName": {
                      "Value #A": "TTL",
                      "instance": ""
                    }
                  }
                }
              ],
              "type": "table"
            },
            {
              "datasource": {
                "type": "prometheus",
                "uid": "${DS_PROMETHEUS}"
              },
              "description": "Time since last successful Vault token renewal",
              "fieldConfig": {
                "defaults": {
                  "color": {
                    "mode": "thresholds"
                  },
                  "custom": {
                    "align": "auto",
                    "displayMode": "auto",
                    "inspect": false
                  },
                  "mappings": [],
                  "thresholds": {
                    "mode": "absolute",
                    "steps": [
                      {
                        "color": "red"
                      },
                      {
                        "color": "#EAB839",
                        "value": 172800010
                      },
                      {
                        "color": "green",
                        "value": 345600000
                      }
                    ]
                  },
                  "unit": "ms"
                },
                "overrides": [
                  {
                    "matcher": {
                      "id": "byName",
                      "options": "TTL"
                    },
                    "properties": [
                      {
                        "id": "custom.displayMode",
                        "value": "color-background"
                      },
                      {
                        "id": "color",
                        "value": {
                          "mode": "thresholds"
                        }
                      }
                    ]
                  },
                  {
                    "matcher": {
                      "id": "byName",
                      "options": "hostname"
                    },
                    "properties": [
                      {
                        "id": "custom.width",
                        "value": 311
                      }
                    ]
                  }
                ]
              },
              "gridPos": {
                "h": 5,
                "w": 8,
                "x": 8,
                "y": 53
              },
              "id": 35,
              "options": {
                "footer": {
                  "fields": "",
                  "reducer": [
                    "sum"
                  ],
                  "show": false
                },
                "showHeader": true,
                "sortBy": []
              },
              "pluginVersion": "9.1.4",
              "targets": [
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "exemplar": false,
                  "expr": "nomad_nomad_vault_token_last_renewal{cluster=\"$cluster\"}",
                  "format": "table",
                  "instant": true,
                  "interval": "",
                  "legendFormat": "ttl",
                  "refId": "A"
                }
              ],
              "title": "Token Last Renew",
              "transformations": [
                {
                  "id": "organize",
                  "options": {
                    "excludeByName": {
                      "Time": true,
                      "__name__": true,
                      "cluster": true,
                      "env": true,
                      "instance": true,
                      "instance_name": true,
                      "instance_private_ip": true,
                      "job": true,
                      "role": true,
                      "service": true
                    },
                    "indexByName": {},
                    "renameByName": {
                      "Value #A": "TTL",
                      "instance": ""
                    }
                  }
                }
              ],
              "type": "table"
            },
            {
              "datasource": {
                "type": "prometheus",
                "uid": "${DS_PROMETHEUS}"
              },
              "description": "Time until next Vault token renewal attempt",
              "fieldConfig": {
                "defaults": {
                  "color": {
                    "mode": "thresholds"
                  },
                  "custom": {
                    "align": "auto",
                    "displayMode": "auto",
                    "inspect": false
                  },
                  "mappings": [],
                  "thresholds": {
                    "mode": "absolute",
                    "steps": [
                      {
                        "color": "red"
                      },
                      {
                        "color": "#EAB839",
                        "value": 172800010
                      },
                      {
                        "color": "green",
                        "value": 345600000
                      }
                    ]
                  },
                  "unit": "ms"
                },
                "overrides": [
                  {
                    "matcher": {
                      "id": "byName",
                      "options": "TTL"
                    },
                    "properties": [
                      {
                        "id": "custom.displayMode",
                        "value": "color-background"
                      },
                      {
                        "id": "color",
                        "value": {
                          "mode": "thresholds"
                        }
                      }
                    ]
                  },
                  {
                    "matcher": {
                      "id": "byName",
                      "options": "hostname"
                    },
                    "properties": [
                      {
                        "id": "custom.width",
                        "value": 311
                      }
                    ]
                  }
                ]
              },
              "gridPos": {
                "h": 5,
                "w": 8,
                "x": 16,
                "y": 53
              },
              "id": 36,
              "options": {
                "footer": {
                  "fields": "",
                  "reducer": [
                    "sum"
                  ],
                  "show": false
                },
                "showHeader": true,
                "sortBy": []
              },
              "pluginVersion": "9.1.4",
              "targets": [
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "exemplar": false,
                  "expr": "nomad_nomad_vault_token_next_renewal{cluster=\"$cluster\"}",
                  "format": "table",
                  "instant": true,
                  "interval": "",
                  "legendFormat": "ttl",
                  "refId": "A"
                }
              ],
              "title": "Token Next Renew",
              "transformations": [
                {
                  "id": "organize",
                  "options": {
                    "excludeByName": {
                      "Time": true,
                      "__name__": true,
                      "cluster": true,
                      "env": true,
                      "instance": true,
                      "instance_name": true,
                      "instance_private_ip": true,
                      "job": true,
                      "role": true,
                      "service": true
                    },
                    "indexByName": {},
                    "renameByName": {
                      "Value #A": "TTL",
                      "instance": ""
                    }
                  }
                }
              ],
              "type": "table"
            },
            {
              "datasource": {
                "type": "prometheus",
                "uid": "${DS_PROMETHEUS}"
              },
              "description": "Time elapsed to manipulate Vault tokens",
              "fieldConfig": {
                "defaults": {
                  "color": {
                    "mode": "palette-classic"
                  },
                  "custom": {
                    "axisCenteredZero": false,
                    "axisColorMode": "text",
                    "axisLabel": "",
                    "axisPlacement": "auto",
                    "barAlignment": 0,
                    "drawStyle": "line",
                    "fillOpacity": 0,
                    "gradientMode": "none",
                    "hideFrom": {
                      "legend": false,
                      "tooltip": false,
                      "viz": false
                    },
                    "lineInterpolation": "linear",
                    "lineWidth": 1,
                    "pointSize": 5,
                    "scaleDistribution": {
                      "type": "linear"
                    },
                    "showPoints": "auto",
                    "spanNulls": false,
                    "stacking": {
                      "group": "A",
                      "mode": "none"
                    },
                    "thresholdsStyle": {
                      "mode": "off"
                    }
                  },
                  "mappings": [],
                  "thresholds": {
                    "mode": "absolute",
                    "steps": [
                      {
                        "color": "green"
                      }
                    ]
                  },
                  "unit": "ns"
                },
                "overrides": []
              },
              "gridPos": {
                "h": 7,
                "w": 24,
                "x": 0,
                "y": 58
              },
              "id": 38,
              "options": {
                "legend": {
                  "calcs": [],
                  "displayMode": "list",
                  "placement": "bottom",
                  "showLegend": true
                },
                "tooltip": {
                  "mode": "single",
                  "sort": "none"
                }
              },
              "targets": [
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "exemplar": true,
                  "expr": "nomad_nomad_vault_create_token{cluster=\"$cluster\",quantile=\"0.9\"}",
                  "interval": "",
                  "legendFormat": "create",
                  "range": true,
                  "refId": "A"
                },
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "exemplar": true,
                  "expr": "nomad_nomad_vault_lookup_token{cluster=\"$cluster\",quantile=\"0.9\"}",
                  "hide": false,
                  "interval": "",
                  "legendFormat": "lookup",
                  "range": true,
                  "refId": "B"
                },
                {
                  "datasource": {
                    "type": "prometheus",
                    "uid": "${DS_PROMETHEUS}"
                  },
                  "editorMode": "code",
                  "exemplar": true,
                  "expr": "nomad_nomad_vault_revoke_token{cluster=\"$cluster\",quantile=\"0.9\"}",
                  "hide": false,
                  "interval": "",
                  "legendFormat": "revoke",
                  "range": true,
                  "refId": "C"
                }
              ],
              "title": "Tokens",
              "type": "timeseries"
            }
          ],
          "schemaVersion": 37,
          "style": "dark",
          "tags": [],
          "templating": {
            "list": [
              {
                "current": {
                  "selected": false,
                  "text": "Prometheus",
                  "value": "Prometheus"
                },
                "hide": 0,
                "includeAll": false,
                "label": "datasource",
                "multi": false,
                "name": "DS_PROMETHEUS",
                "options": [],
                "query": "prometheus",
                "refresh": 1,
                "regex": "",
                "skipUrlSync": false,
                "type": "datasource"
              },
              {
                "current": {},
                "datasource": {
                  "type": "prometheus",
                  "uid": "${DS_PROMETHEUS}"
                },
                "definition": "label_values(nomad_client_uptime, cluster)",
                "hide": 0,
                "includeAll": false,
                "label": "Cluster",
                "multi": false,
                "name": "cluster",
                "options": [],
                "query": {
                  "query": "label_values(nomad_client_uptime, cluster)",
                  "refId": "StandardVariableQuery"
                },
                "refresh": 1,
                "regex": "",
                "skipUrlSync": false,
                "sort": 0,
                "type": "query"
              }
            ]
          },
          "time": {
            "from": "now-6h",
            "to": "now"
          },
          "timepicker": {},
          "timezone": "",
          "title": "Server",
          "uid": "xDnB_0G4z",
          "version": 1,
          "weekStart": ""
        }
        EOF
        destination     = "local/grafana/provisioning/dashboards/nomad/server.json"
        left_delimiter  = "[["
        right_delimiter = "]]"
      }
    }
  }
}
