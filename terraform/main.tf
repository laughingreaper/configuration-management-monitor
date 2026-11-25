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

# prometheus container
resource "docker_image" "prometheus" {
  name         = "prom/prometheus:latest"
  keep_locally = false
}

resource "docker_container" "prometheus-srv" {
  image = docker_image.prometheus.image_id
  name  = "prometheus-srv"

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
    aliases = ["prometheus-srv"]
  }
}

# grafana container
resource "docker_image" "grafana" {
  name         = "grafana/grafana:latest"
  keep_locally = false
}

resource "docker_container" "grafana-srv" {
  image = docker_image.grafana.image_id
  name  = "grafana-srv"

  ports {
    internal = 3000
    external = var.grafana_ext_port
  }

  # allow container to be reachable by hostname
  networks_advanced {
    name    = docker_network.project-net.name
    aliases = ["grafana-srv"]
  }
}

# ansible control container
resource "docker_image" "ansible" {
  name         = "alpine/ansible:latest"
  keep_locally = false
}

resource "docker_container" "ansible-srv" {
  image = docker_image.ansible.image_id
  name  = "ansible-srv"

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
    aliases = ["ansible-srv"]
  }
}

# managed ubuntu node
resource "docker_image" "ubuntu-26_04" {
  name         = "ubuntu:26.04"
  keep_locally = false
}

resource "docker_container" "ubuntu-mngd" {
  image = docker_image.ubuntu-26_04.image_id
  name  = "ubuntu-mngd"

  # install python3 and common tools for ansible, then keep alive
  entrypoint = ["/bin/sh", "-c"]
  command    = ["apt-get update && apt-get install -y python3 sudo curl tar procps iputils-ping && tail -f /dev/null"]

  networks_advanced {
    name    = docker_network.project-net.name
    aliases = ["node-ubuntu"]
  }
}
