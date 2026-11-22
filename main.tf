terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# pihole container (managed and monitored node)
resource "docker_image" "pihole" {
  name         = "pihole/pihole:latest"
  keep_locally = false
}

resource "docker_container" "pihole-server" {
  image = docker_image.pihole.image_id
  name  = "pihole-confmanage" # Riley already has a container called "pihole"

  capabilities {
    add = ["NET_ADMIN"]
  }

  # env variable kept in terraform.tfvars
  env = [
    "TZ=${var.pihole_tz}",
    "WEBPASSWORD=${var.pihole_password}"
  ]

  # external port mappings also in terraform.tfvars
  # (because Riley already has a pihole running)
  ports {
    internal = 53
    external = var.pihole_ext_port_dns
    protocol = "tcp"
  }

  ports {
    internal = 53
    external = var.pihole_ext_port_dns
    protocol = "udp"
  }

  ports {
    internal = 80
    external = var.pihole_ext_port_web
    protocol = "tcp"
  }
}

# grafana container
resource "docker_image" "grafana" {
  name         = "grafana/grafana:latest"
  keep_locally = false
}

resource "docker_container" "grafana_server" {
  image = "grafana/grafana:latest"
  name  = "grafana"

  ports {
    internal = 3000
    external = var.grafana_ext_port
  }
}

# ansible control container
resource "docker_image" "ansible" {
  name         = "alpine/ansible:latest"
  keep_locally = false
}

resource "docker_container" "ansible_runner" {
  image   = docker_image.ansible.image_id
  name    = "ansible_node"
  command = ["tail", "-f", "/dev/null"]
}
