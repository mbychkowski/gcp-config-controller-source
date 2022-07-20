variable "project" {
  type        = string
  description = "the GCP project id where the cluster will be created"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "the GCP region where the cluster will be created"
}

variable "zone" {
  type        = string
  default     = "us-central1-c"
  description = "the GCP zone in the region where the cluster will be created"
}
