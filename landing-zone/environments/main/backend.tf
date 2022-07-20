terraform {
  backend "gcs" {
    bucket = "tfstate-landing-zone"
    prefix = "env/main"
  }
}
