module "cloud-storage" {
  source  = "terraform-google-modules/cloud-storage/google"
  version = "3.2.0"
  # insert the 3 required variables here
  project_id  = "${var.project}"
  names = "${var.names}"
  prefix = "${var.env}"
  versioning = {
    first = true
  }  
}