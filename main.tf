provider "google" {
    version     = "~> 3"
    region      = var.region
    zone        = var.zone
    project     = var.project
}

data "google_project" "project" {
  project_id = var.project
}

# IAM permissions for cloudbuild to use K8s
resource "google_project_iam_member" "cloud_build_GKE_iam" {
  project = data.google_project.project.number
  role    = "roles/container.developer"
  member  = join("",["serviceAccount:",data.google_project.project.number,"@cloudbuild.gserviceaccount.com"])
}


resource "google_compute_network" "network" {
  name = "network"
  auto_create_subnetworks = false
  routing_mode = "GLOBAL"
  project = var.project
}

resource "google_compute_subnetwork" "subnet" {
  name          = "subnet"
  ip_cidr_range = "10.2.0.0/16"
  region        = var.region
  network       = google_compute_network.network.id
  secondary_ip_range {
    range_name    = "range-1"
    ip_cidr_range = "192.168.0.0/18"
  }
  secondary_ip_range {
    range_name    = "range-2"
    ip_cidr_range = "192.168.128.0/20"
  }
}


resource "google_container_cluster" "dyson_cluster" {
  project = var.project
  name               = "dyson-cluster"
  location           = var.zone
  remove_default_node_pool = false
#   networking_mode = "VPC_NATIVE"
  network = google_compute_network.network.id
  subnetwork = google_compute_subnetwork.subnet.id  
  ip_allocation_policy {
    cluster_secondary_range_name = "range-1"
    services_secondary_range_name = "range-2"
  }
  workload_identity_config {
    identity_namespace = "${var.project}.svc.id.goog"
  }
  node_pool {
      initial_node_count = 1 
      autoscaling {
          min_node_count = 1
          max_node_count = 5
      }
  }
}

# Workload Identity IAM binding for Dyson in default namespace.
resource "google_service_account_iam_member" "dyson-sa-workload-identity" {
  service_account_id = google_service_account.dyson.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project}.svc.id.goog[default/dyson]"
  depends_on = [
    google_container_cluster.dyson_cluster
  ]
}


# Service account used by Dyson
resource "google_service_account" "dyson" {
  project      = var.project
  account_id   = "dyson-sa"
  display_name = "dyson-sa"
}
