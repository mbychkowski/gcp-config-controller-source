variable "names" {
  type        = list(string)
  default     = ["first", "second"]
  description = "the name of the cloud storage bucket"
}

variable "project" {
  type        = string
  description = "the ID of the GCP project in which to provision resources."
}

variable "env" {
  type        = string
  description = "env name that will be prefix to bucket name"
}