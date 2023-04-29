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

locals {
  cluster_endpoint       = "https://${google_container_cluster.jss_pos.endpoint}"
  cluster_ca_certificate = google_container_cluster.jss_pos.master_auth[0].cluster_ca_certificate
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

resource "random_password" "jss_pos_sql" {
  length           = 20
  min_lower        = 4
  min_numeric      = 4
  min_upper        = 4
  override_special = "!#%*()-_=+[]{}:?"
}

module "database" {
  depends_on           = [module.enable_google_apis]
  source               = "./modules/database"
  region               = var.region
  private_network_id   = google_compute_network.jss_pos.id
  sql_user_password    = random_password.jss_pos_sql.result
  availability_type    = "REGIONAL"
  resource_name_suffix = var.resource_name_suffix
}

resource "google_compute_address" "jss_pos" {
  depends_on   = [module.enable_google_apis]
  name         = "jss-pos-${var.resource_name_suffix}"
  project      = var.project_id
  region       = var.region
  address_type = "EXTERNAL"
}

resource "google_container_cluster" "jss_pos" {
  depends_on = [
    module.enable_google_apis,
    google_compute_address.jss_pos,
  ]

  provider         = google-beta # Needed for the google_gkehub_feature Terraform module.
  name             = "jss-pos-${var.resource_name_suffix}"
  project          = var.project_id
  location         = var.region
  resource_labels  = var.labels
  network          = google_compute_network.jss_pos.id
  enable_autopilot = true

  cluster_autoscaling {
    auto_provisioning_defaults {
      service_account = google_service_account.jss_pos.email
    }
  }

  ip_allocation_policy {
    # Need an empty ip_allocation_policy to overcome an error related to autopilot node pool constraints.
    # Workaround from https://github.com/hashicorp/terraform-provider-google/issues/10782#issuecomment-1024488630
  }

  node_config {
    service_account = google_service_account.jss_pos.email
  }
}

module "helm" {
  depends_on = [
    google_container_cluster.jss_pos,
    google_compute_address.jss_pos,
  ]
  source = "./modules/helm"
  helm_values = [
    {
      name  = "loadbalancer_ip"
      value = google_compute_address.jss_pos.address
    },
  ]
  helm_secret_values = []
}
