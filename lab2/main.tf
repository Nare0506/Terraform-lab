terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

provider "google" {
  project = "tf-labs-nare0506"
  region  = "us-central1"
  zone    = "us-central1-a"
}

resource "google_storage_bucket" "lab" {
  name                        = "tf-labs-nare0506-bucket-01"
  location                    = "US"
  force_destroy               = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "hello" {
  name    = "hello.txt"
  bucket  = google_storage_bucket.lab.name
  content = "Uploaded by Terraform!"
}

output "bucket_url" {
  value = google_storage_bucket.lab.url
}

# ---------- Network ----------
resource "google_compute_network" "vpc" {
  name                    = "lab-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "lab-subnet"
  ip_cidr_range = "10.10.0.0/24"
  network       = google_compute_network.vpc.id
}

# ---------- Firewall: allow web traffic ----------
resource "google_compute_firewall" "http" {
  name          = "lab-allow-http"
  network       = google_compute_network.vpc.name
  target_tags   = ["web"]
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}

# ---------- Web server VM ----------
resource "google_compute_instance" "web" {
  name         = "lab-web"
  machine_type = "e2-micro"
  tags         = ["web"]
  labels       = { env = "lab", owner = "narendhar" }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {}
  }

  metadata_startup_script = <<-SCRIPT
    apt-get update
    apt-get install -y nginx
    echo "<h1>Hello from Terraform, built by Narendhar!</h1>" > /var/www/html/index.html
  SCRIPT
}

output "website_url" {
  value = "http://${google_compute_instance.web.network_interface[0].access_config[0].nat_ip}"
}
