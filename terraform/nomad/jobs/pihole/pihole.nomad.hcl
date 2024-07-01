job "pihole" {
  datacenters = ["dc1"]
  
  type = "service"
  
  group "pihole" {
    count = 1
    
    restart {
      attempts = 5
      delay    = "15s"
    }
    
    task "app" {
      driver = "docker"
      config {
        image = "pihole/pihole:2024.06.0"
        mounts = [
          {
            type     = "bind"
            target   = "/etc/pihole"
            source   = "/mnt/storage/nomad/data/pihole/pihole"
            readonly = false
          },
          {
            type     = "bind"
            target   = "/etc/dnsmasq.d"
            source   = "/mnt/storage/nomad/data/pihole/dnsmasq.d"
            readonly = false
          },
        ]
        port_map {
          dns  = 53
          http = 80
        }
        dns_servers = [
          "127.0.0.1",
          "1.1.1.1",
        ]
      }
      
      env = {
        "TZ"           = "insert_your_timezone"
        "WEBPASSWORD"  = "insert_your_password"
        "DNS1"         = "insert_your_dns_server_ip"
        "DNS2"         = "no"
        "INTERFACE"    = "eth0"
        "VIRTUAL_HOST" = "insert_your_virtual_host_fqdn"
        "ServerIP"     = "insert_your_raspberry_pi_server_ip"
      }
      
      resources {
        cpu    = 100
        memory = 128
        network {
          port "dns" {
            static = 53
          }
          
          port "http" {}
        }
      }
      
      service {
        name = "pihole-gui"
        port = "http"
      }
    }
  }
}