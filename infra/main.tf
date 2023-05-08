/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// Load the default client configuration used by the Google Cloud provider.
data "google_client_config" "default" {}

locals {
  cluster_endpoint       = "https://${module.gke_cluster.cluster_endpoint}"
  cluster_ca_certificate = module.gke_cluster.cluster_ca_certificate
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "helm" {
  kubernetes {
    host                   = local.cluster_endpoint
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(local.cluster_ca_certificate)
  }
}

module "enable_google_apis" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  version                     = "~> 14.0"
  project_id                  = var.project_id
  disable_services_on_destroy = false
  activate_apis = [
    "cloudresourcemanager.googleapis.com",
    "container.googleapis.com",
    "dns.googleapis.com",
    "gkehub.googleapis.com",
    "iam.googleapis.com",
    "monitoring.googleapis.com",
  ]
}

resource "google_service_account" "jss_pos_service_account" {
  depends_on = [
    module.enable_google_apis
  ]

  account_id   = "jss-pos-service-account-${var.resource_name_suffix}"
  display_name = "jss-pos-service-account-${var.resource_name_suffix}"
  description  = "Service Account used by the Dynamic Point-of-sale Java App Jump Start Solution"
  project      = var.project_id
}

resource "google_compute_address" "jss_pos_ip" {
  depends_on = [
    module.enable_google_apis
  ]
  name         = "jss-pos-ip-${var.resource_name_suffix}"
  project      = var.project_id
  region       = var.region
  address_type = "EXTERNAL"
}

module "gke_cluster" {
  depends_on = [
    module.enable_google_apis,
    google_compute_address.jss_pos_ip,
  ]
  source          = "./modules/gke-cluster"
  project_id      = var.project_id
  region          = var.region
  name_suffix     = var.resource_name_suffix
  labels          = var.labels
  service_account = google_service_account.jss_pos_service_account.email
}


module "helm" {
  depends_on = [
    module.gke_cluster,
    google_compute_address.jss_pos_ip,
  ]
  source = "./modules/helm"
  helm_values = [
    {
      name  = "loadbalancer_ip"
      value = google_compute_address.jss_pos_ip.address
    },
  ]
}
