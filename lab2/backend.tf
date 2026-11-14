terraform {
  backend "gcs" {
    bucket = "tf-state-nare0506"
    prefix = "lab2"
  }
}
