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
  cluster_endpoint           = "https://${google_container_cluster.jss_pos.endpoint}"
  cluster_ca_certificate     = google_container_cluster.jss_pos.master_auth[0].cluster_ca_certificate
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

resource "google_project_iam_member" "google_service_account_is_spanner_user" {
  project = var.project_id
  role    = "roles/spanner.databaseUser"
  member  = "serviceAccount:${google_service_account.jss_pos.email}"
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

########################################################################
#            Google Kubernetes Engine Cluster resources
########################################################################

resource "google_container_cluster" "jss_pos" {
  depends_on = [
    module.enable_google_apis,
    google_compute_address.jss_pos,
  ]
  name             = "jss-pos-cluster-${var.resource_name_suffix}"
  project          = var.project_id
  location         = var.region
  network          = google_compute_network.jss_pos.id
  enable_autopilot = true
  resource_labels  = var.labels

  cluster_autoscaling {
    auto_provisioning_defaults {
      service_account = google_service_account.jss_pos.email
    }
  }

  ip_allocation_policy {
    # Need an empty ip_allocation_policy to overcome an error related to autopilot node pool constraints.
    # Workaround from https://github.com/hashicorp/terraform-provider-google/issues/10782#issuecomment-1024488630
  }
}

resource "kubernetes_service_account" "jss_pos" {
  depends_on = [google_container_cluster.jss_pos]
  metadata {
    name      = local.kubernetes_service_account
    namespace = local.kubernetes_namespace
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.jss_pos.email
    }
  }
}

#-----------------------------------------------------------------------

resource "google_service_account_iam_member" "jss_poss_impersonate_google_sa" {
  depends_on         = [kubernetes_service_account.jss_pos]
  service_account_id = google_service_account.jss_pos.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${local.kubernetes_namespace}/${local.kubernetes_service_account}]"
}

########################################################################
#                       Google Spanner resources
########################################################################

resource "google_spanner_instance" "jss_pos" {
  config       = "regional-us-central1"
  display_name = "jss-pos"
  project      = var.project_id
  num_nodes    = 1
  labels       = {}
}

resource "google_spanner_database" "jss_pos" {
  instance                 = google_spanner_instance.jss_pos.name
  project                  = var.project_id
  name                     = "pos_db"
  database_dialect         = "GOOGLE_STANDARD_SQL"
  version_retention_period = "3d"
  deletion_protection      = false
  ddl = [
    file("${path.module}/sql-schema/items.sql"),
    file("${path.module}/sql-schema/payments.sql"),
    file("${path.module}/sql-schema/payment_units.sql"),
  ]
}

#-----------------------------------------------------------------------

########################################################################
#  Helm release resource to deploy the application into the GKE cluster
########################################################################

resource "helm_release" "jss_point_of_sale" {
  name  = "jss-point-of-sale"
  chart = "${path.module}/charts"
  values = [
    file("${path.module}/charts/values.yaml"),
  ]

  set {
    name  = "loadbalancer_ip"
    value = google_compute_address.jss_pos.address
  }
  set {
    name  = "service_account"
    value = local.kubernetes_service_account
  }
  set {
    name  = "project_id"
    value = var.project_id
  }
  set {
    name  = "spanner_id"
    value = google_spanner_instance.jss_pos.name
  }
  set {
    name  = "spanner_database"
    value = google_spanner_database.jss_pos.name
  }
}

#-----------------------------------------------------------------------
