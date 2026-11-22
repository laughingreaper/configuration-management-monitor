variable "pihole_tz" {
  description = "Timezone for the Pi-hole container"
  type        = string
  default     = "America/New_York"
}

variable "pihole_password" {
  description = "Web admin password for Pi-hole"
  type        = string
  sensitive   = true
}

variable "pihole_ext_port_dns" {
  description = "External port for Pi-hole DNS (TCP and UDP)"
  type        = number
  default     = 53
}

variable "pihole_ext_port_web" {
  description = "External port for Pi-hole Web Admin"
  type        = number
  default     = 80
}

variable "grafana_ext_port" {
  description = "External port for Grafana"
  type        = number
  default     = 3000
}
