output "gkeZone" {
    value = google_container_cluster.gke_cluster.zone
}

output "project" {
    value = google_container_cluster.gke_cluster.project
}

output "location" {
    value = google_container_cluster.gke_cluster.location
}
