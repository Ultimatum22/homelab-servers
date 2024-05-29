job "mqtt" {
  
  type = "service"

  group "mqtt" {
    count = 1
	
    network {
      port "mqtt" {
        to = 1883
      }
    }

    task "mqtt" {
      driver = "docker"

      config {
        image = "eclipse-mosquitto:2.0.18"
        ports = ["mqtt"]
      }
    }
  }
}
