variable "region" {
    type        = string
    description = "Default region for GCP resources"
    default     = "us-central1"
}

variable "zone" {
    type        = string
    description = "Default zone for GCP resources"
    default     = "us-central1-f"
}

variable "project" {
    type        = string
    description = "The project in which to place all new resources"
}



variable "primary_ip" {
    type        = string
    description = "The primary IP for GKE VPC"
    default = "10.2.0.0/16"
}


variable "pod_ip" {
    type        = string
    description = "The pod IP range for GKE"
    default = "192.168.0.0/18"
}


variable "service_ip" {
    type        = string
    description = "The service IP range for GKE"
    default = "192.168.128.0/20"
}

variable "cluster_name" {
    type        = string
    description = "Name of GKE Cluster"
    default = "cluster1"
}

