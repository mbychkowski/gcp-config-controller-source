module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 5.1.0"

  network_name            = "${var.env}-vpc-cc"
  project_id              = var.project
  routing_mode            = "GLOBAL"
  auto_create_subnetworks = true
  mtu                     = 1460

  subnets = [
    {
      subnet_name           = "${var.env}-subnet-gke"
      subnet_ip             = "10.0.0.0/28"
      subnet_region         = "${var.region}"
      subnet_private_access = "true"
      subnet_flow_logs      = "true"
    }
  ]
}

module "firewall_rules" {
  source       = "terraform-google-modules/network/google//modules/firewall-rules"
  project_id   = var.project
  network_name = module.vpc.network_name

  rules = [
    {
      name                    = "allow-all-internal"
      description             = null
      direction               = "INGRESS"
      priority                = null
      ranges                  = ["10.0.0.0/8"]
      source_tags             = null
      source_service_accounts = null
      target_tags             = null
      target_service_accounts = null

      allow = [
        {
          protocol = "tcp"
          ports    = []
        },
        {
          protocol = "udp"
          ports    = []
        },
        {
          protocol = "icmp"
          ports    = []
        }
      ]
      deny = []
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
    },
    {
      name                    = "allow-all-egress"
      description             = null
      direction               = "EGRESS"
      priority                = null
      ranges                  = ["0.0.0.0/0"]
      source_tags             = null
      source_service_accounts = null
      target_tags             = null
      target_service_accounts = null
      allow = [
        {
          protocol = "tcp"
          ports    = []
        },
        {
          protocol = "udp"
          ports    = []
        },
        {
          protocol = "icmp"
          ports    = []
        }
      ]
      deny = []
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
    }
  ]
}

module "cloud_router" {
  source  = "terraform-google-modules/cloud-router/google"

  name    = "${var.env}-router"
  region  = var.region
  network = module.vpc.network_id
  project = var.project

  bgp = {
    asn = 64514
  }  

  nats = [{
    name                               = "${var.env}-router-nat"
    nat_ip_allocate_option             = "AUTO_ONLY"
    source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
    min_ports_per_vm                   = 1024    
    log_config = {
      enable = true
      filter = "ERRORS_ONLY"
    }    
  }]
}
