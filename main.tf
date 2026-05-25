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

resource "docker_image" "nginx" {
  name         = "mitpayk/my-nginx:latest"
  keep_locally = false
}

resource "docker_container" "web1" {
  name  = "web1"
  image = docker_image.nginx.image_id
  ports {
    internal = 80
    external = 8081
  }
}

resource "docker_container" "web2" {
  name  = "web2"
  image = docker_image.nginx.image_id
  ports {
    internal = 80
    external = 8082
  }
}

output "server_ip" {
  value = "127.0.0.1"
}

output "ansible_inventory" {
  value = <<-EOT
    [webservers]
    web1 ansible_host=127.0.0.1 ansible_connection=local container_port=8081
    web2 ansible_host=127.0.0.1 ansible_connection=local container_port=8082
  EOT
}
