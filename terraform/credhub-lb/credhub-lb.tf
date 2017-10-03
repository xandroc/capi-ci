# INPUTS

variable "json_key" {}
variable "region" {
  default = "us-central1"
}

variable "project_id" {
  type = "string"
}

variable "network_name" {
  type = "string"
}


# RESOURCES

provider "google" {
  credentials = "${var.json_key}"
  project = "${var.project_id}"
  region = "${var.region}"
}

resource "google_compute_firewall" "firewall-credhub" {
  name    = "${var.project_id}-credhub-open"
  network = "${var.network_name}"
  allow {
    protocol = "tcp"
    ports    = ["8844"]
  }
  target_tags = ["${google_compute_target_pool.target-pool.name}"]
}

resource "google_compute_address" "credhub-address" {
  name = "${var.project_id}-credhub"
}

resource "google_compute_target_pool" "target-pool" {
  name = "${var.project_id}-credhub"
  session_affinity = "NONE"
}

resource "google_compute_forwarding_rule" "forwarding-rule" {
  name        = "${var.project_id}-credhub"
  target      = "${google_compute_target_pool.target-pool.self_link}"
  port_range  = "8844"
  ip_protocol = "TCP"
  ip_address  = "${google_compute_address.credhub-address.address}"
}

# OUTPUTS

output "credhub_target_pool" {
  value = "${google_compute_target_pool.target-pool.name}"
}

output "credhub_target_tags" {
  value = "${google_compute_firewall.firewall-credhub.target_tags}"
}
