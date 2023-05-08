# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

locals {
  cluster_endpoint           = "https://${module.gke_cluster.cluster_endpoint}"
  cluster_ca_certificate     = module.gke_cluster.cluster_ca_certificate
  kubernetes_service_account = "spanner-access-sa"
  kubernetes_namespace       = "default"
}

// Load the default client configuration used by the Google Cloud provider.
data "google_client_config" "default" {}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "kubernetes" {
  host                   = local.cluster_endpoint
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(local.cluster_ca_certificate)
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
    "spanner.googleapis.com",
  ]
}

resource "google_service_account" "jss_pos" {
  depends_on   = [module.enable_google_apis]
  account_id   = "jss-pos-${var.resource_name_suffix}"
  display_name = "jss-pos-${var.resource_name_suffix}"
  description  = "Service Account used by the Dynamic Point-of-sale Java App Jump Start Solution"
  project      = var.project_id
}

resource "google_compute_network" "jss_pos" {
  depends_on              = [module.enable_google_apis]
  project                 = var.project_id
  name                    = "jss-pos-${var.resource_name_suffix}"
  auto_create_subnetworks = true
}

resource "google_compute_address" "jss_pos" {
  depends_on   = [module.enable_google_apis]
  name         = "jss-pos-${var.resource_name_suffix}"
  project      = var.project_id
  region       = var.region
  address_type = "EXTERNAL"
}

module "gke_cluster" {
  depends_on = [
    module.enable_google_apis,
    google_compute_address.jss_pos_ip,
  ]
  source                   = "./modules/gke-cluster"
  project_id               = var.project_id
  region                   = var.region
  name_suffix              = var.resource_name_suffix
  labels                   = var.labels
  network                  = google_compute_network.jss_pos.id
  google_service_account   = google_service_account.jss_pos
  k8s_service_account_name = local.kubernetes_service_account
  k8s_namespace            = local.kubernetes_namespace
}

module "spanner" {
  depends_on = [module.enable_google_apis]
  source     = "./modules/spanner"
  project_id = var.project_id
}

module "helm" {
  depends_on = [
    module.gke_cluster,
    module.spanner,
    google_compute_address.jss_pos,
  ]
  source = "./modules/helm"
  helm_values = [
    {
      name  = "loadbalancer_ip"
      value = google_compute_address.jss_pos.address
    },
    {
      name  = "service_account"
      value = local.kubernetes_service_account
    },
    {
      name  = "project_id"
      value = var.project_id
    },
    {
      name  = "spanner_id"
      value = module.spanner.spanner_instance
    },
    {
      name  = "database"
      value = module.spanner.spanner_db_name
    },
  ]
}
