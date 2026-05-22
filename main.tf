terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_network" "lab_network" {
  name = "lab8_network"
}

resource "docker_image" "nginx" {
  name         = "mitpayk/my-nginx:latest"
  keep_locally = false
}

resource "docker_image" "node_exporter" {
  name         = "prom/node-exporter:latest"
  keep_locally = false
}

resource "docker_image" "prometheus" {
  name         = "prom/prometheus:latest"
  keep_locally = false
}

resource "docker_image" "grafana" {
  name         = "grafana/grafana:latest"
  keep_locally = false
}

resource "docker_container" "app" {
  name  = "app_node"
  image = docker_image.nginx.image_id
  networks_advanced {
    name = docker_network.lab_network.name
  }
  ports {
    internal = 80
    external = 8081
  }
}

resource "docker_container" "node_exporter" {
  name  = "node_exporter"
  image = docker_image.node_exporter.image_id
  networks_advanced {
    name = docker_network.lab_network.name
  }
  ports {
    internal = 9100
    external = 9100
  }
}

resource "docker_container" "prometheus" {
  name  = "prometheus"
  image = docker_image.prometheus.image_id
  networks_advanced {
    name = docker_network.lab_network.name
  }
  ports {
    internal = 9090
    external = 9090
  }
  volumes {
    host_path      = "/home/vagrant/lab8/prometheus.yml"
    container_path = "/etc/prometheus/prometheus.yml"
  }
}

resource "docker_container" "grafana" {
  name  = "grafana"
  image = docker_image.grafana.image_id
  networks_advanced {
    name = docker_network.lab_network.name
  }
  ports {
    internal = 3000
    external = 3000
  }
}

output "server_ip" {
  value = "127.0.0.1"
}

output "ansible_inventory" {
  value = <<-EOT
[app_node]
app ansible_host=127.0.0.1 ansible_connection=local

[monitor_node]
monitor ansible_host=127.0.0.1 ansible_connection=local
EOT
}
