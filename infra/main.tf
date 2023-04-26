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

provider "google" {
  project = var.project_id
}

provider "google-beta" {
  project = var.project_id
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
    "monitoring.googleapis.com ",
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

resource "google_container_cluster" "jss_pos_cluster" {
  depends_on = [
    module.enable_google_apis
  ]
  # Needed for the google_gkehub_feature Terraform module.
  provider = google-beta
  # -----------

  name             = "jss-pos-cluster-${var.resource_name_suffix}"
  project          = var.project_id
  location         = var.region
  enable_autopilot = true
  resource_labels  = var.labels

  cluster_autoscaling {
    auto_provisioning_defaults {
      service_account = google_service_account.jss_pos_service_account.email
    }
  }

  ip_allocation_policy {
    # Need an empty ip_allocation_policy to overcome an error related to autopilot node pool constraints.
    # Workaround from https://github.com/hashicorp/terraform-provider-google/issues/10782#issuecomment-1024488630
  }

  node_config {
    service_account = google_service_account.jss_pos_service_account.email
  }
}

module "helm" {
  depends_on = [
    google_container_cluster.jss_pos_cluster,
  ]
  source                 = "./helm"
  cluster_endpoint       = "https://${google_container_cluster.jss_pos_cluster.endpoint}"
  cluster_ca_certificate = google_container_cluster.jss_pos_cluster.master_auth[0].cluster_ca_certificate
  entries = []
  secret_entries = []
}
