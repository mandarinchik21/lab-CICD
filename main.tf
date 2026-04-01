terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  credentials = file("gcp-key.json")
  project     = "whole-cloth-491815-n5"
  region      = "europe-west1"
  zone        = "europe-west1-b"
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

resource "google_compute_instance" "web_server" {
  name         = "lab-vm"
  machine_type = "e2-micro"

  tags = ["http-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 10
    }
  }

  network_interface {
    network = "default"
    access_config {} # Це надає зовнішню IP-адресу
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y docker.io
    systemctl enable docker
    systemctl start docker
    docker pull mandarinchik2106/lab-web:latest
    docker run -d --name lab-container -p 80:80 mandarinchik2106/lab-web:latest
    docker run -d --name watchtower \
      -v /var/run/docker.sock:/var/run/docker.sock \
      containrrr/watchtower --interval 30
  EOT

  labels = {
    name        = "lab-terraform-instance"
    environment = "education"
  }
}

output "instance_public_ip" {
  description = "Публічна IP-адреса створеного сервера"
  value       = google_compute_instance.web_server.network_interface[0].access_config[0].nat_ip
}
