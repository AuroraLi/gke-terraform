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
  ip_cidr_range = var.primary_ip 
  region        = var.region
  network       = google_compute_network.network.id
  secondary_ip_range {
    range_name    = "range-1"
    ip_cidr_range = var.pod_ip
  }
  secondary_ip_range {
    range_name    = "range-2"
    ip_cidr_range = var.service_ip
  }
}


resource "google_container_cluster" "gke_cluster" {
  project = var.project
  name               = var.cluster_name
  location           = var.region
  remove_default_node_pool = true
  initial_node_count = 1
  network = google_compute_network.network.id
  subnetwork = google_compute_subnetwork.subnet.id  
  ip_allocation_policy {
    cluster_secondary_range_name = "range-1"
    services_secondary_range_name = "range-2"
  }
  workload_identity_config {
    identity_namespace = "${var.project}.svc.id.goog"
  }
  lifecycle {
    prevent_destroy = true
  }
}


resource "google_container_node_pool" "gke_pool" {
  project    = var.project
  name       = "${var.cluster_name}-pool"
  location   = var.region
  cluster    = google_container_cluster.gke_cluster.name
  initial_node_count = 1
 
  autoscaling {
    min_node_count = 0
    max_node_count = 4
  }

  management {
    auto_repair = "true"
    auto_upgrade = "true"
  }

  node_config {
    machine_type = "e2-standard-2"  
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
    metadata = {
      disable-legacy-endpoints = "true"
    }
    
  }
}


# Workload Identity IAM binding for GKE in default namespace.
resource "google_service_account_iam_member" "gke-sa-workload-identity" {
  service_account_id = google_service_account.gkesa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project}.svc.id.goog[default/default]"
  depends_on = [
    google_container_cluster.gke_cluster
  ]
}


# Service account used by GKE
resource "google_service_account" "gkesa" {
  project      = var.project
  account_id   = "${var.cluster_name}-sa"
  display_name = "${var.cluster_name}-sa"
}
