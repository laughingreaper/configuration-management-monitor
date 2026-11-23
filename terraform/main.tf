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

# create project network
resource "docker_network" "project-net" {
  name = "project-net"
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

  # allow container to be reachable by hostname
  networks_advanced {
    name    = docker_network.project-net.name
    aliases = ["pihole-server"]
  }
}

# prometheus container
resource "docker_image" "prometheus" {
  name         = "prom/prometheus:latest"
  keep_locally = false
}

resource "docker_container" "prometheus_server" {
  image = docker_image.prometheus.image_id
  name  = "prometheus"

  # enable lifecycle API for ansible
  command = [
    "--config.file=/etc/prometheus/prometheus.yml",
    "--storage.tsdb.path=/prometheus",
    "--web.enable-lifecycle"
  ]

  ports {
    internal = 9090
    external = var.prometheus_ext_port
  }

  networks_advanced {
    name    = docker_network.project-net.name
    aliases = ["prometheus"]
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

  # allow container to be reachable by hostname
  networks_advanced {
    name    = docker_network.project-net.name
    aliases = ["grafana"]
  }
}

# ansible control container
resource "docker_image" "ansible" {
  name         = "alpine/ansible:latest"
  keep_locally = false
}

resource "docker_container" "ansible-node" {
  image = docker_image.ansible.image_id
  name  = "ansible-node"

  # install docker-cli
  entrypoint = ["/bin/sh", "-c"]
  command    = ["apk add --no-cache docker-cli && tail -f /dev/null"]

  # mount docker
  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }

  # mount ansible files
  volumes {
    host_path      = abspath("${path.module}/../ansible")
    container_path = "/ansible"
  }

  # allow container to be reachable by hostname
  networks_advanced {
    name    = docker_network.project-net.name
    aliases = ["ansible-node"]
  }
}
