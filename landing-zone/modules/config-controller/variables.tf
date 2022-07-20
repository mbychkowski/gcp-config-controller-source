variable "project" {
  type        = string
  description = "the GCP project id"
}

variable "env" {
  type        = string
  description = "env name that will be pre-appended to most cloud service names"
}

variable "region" {
  type        = string
  description = "region for subnet where config controller will reside"
}
