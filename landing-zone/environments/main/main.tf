module "enabled_google_apis" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 11.3"

  project_id                  = var.project
  disable_services_on_destroy = false

  activate_apis = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "gkehub.googleapis.com",
    "anthosconfigmanagement.googleapis.com",
    "cloudresourcemanager.googleapis.com",
	  "krmapihosting.googleapis.com",
	  "monitoring.googleapis.com",
	  "cloudasset.googleapis.com",
	  "secretmanager.googleapis.com",
	  "cloudbuild.googleapis.com",
	  "orgpolicy.googleapis.com"
  ]
}

module "tf-state-bucket" {
  source  = "../../modules/cloud-storage"
  project = var.project
  env     = local.env
}

module "vpc" {
  source  = "../../modules/vpc"
  project = var.project
  region  = var.region
  env     = local.env
}
