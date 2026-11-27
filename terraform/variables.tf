variable "grafana_ext_port" {
  description = "External port for Grafana"
  type        = number
  default     = 3000
}

variable "prometheus_ext_port" {
  description = "External port for Prometheus"
  type        = number
  default     = 9090
}
