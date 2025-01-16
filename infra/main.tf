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
  kubernetes_service_account = "pos-access-sa"
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

// Enable all the Google Cloud APIs required for this solution
module "enable_google_apis" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  version                     = "~> 18.0"
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

// Create a Google Service Account. This service account will be used by the
// cluster autoscaler of the Google Kubernetes Engine cluster and by the Point
// of sale application Pod, when accessing the Cloud Spanner instance. For the
// latter use-case, Workload Identity is used with a Kubernetes Service Account
resource "google_service_account" "jss_pos" {
  depends_on   = [module.enable_google_apis]
  account_id   = "jss-pos-${var.resource_name_suffix}"
  display_name = "jss-pos-${var.resource_name_suffix}"
  description  = "Service Account used by the Dynamic Point-of-sale Java App Jump Start Solution"
  project      = var.project_id
}

// Add the required roles to the Google Service Account to be used alongside the
// Kubernetes Service Account to access Spanner via WorkloadIdentity
resource "google_project_iam_member" "google_service_account_is_spanner_user" {
  project = var.project_id
  role    = "roles/spanner.databaseUser"
  member  = "serviceAccount:${google_service_account.jss_pos.email}"
}

resource "google_project_iam_member" "google_service_account_is_trace_agent" {
  project = var.project_id
  role    = "roles/cloudtrace.agent"
  member  = "serviceAccount:${google_service_account.jss_pos.email}"
}

resource "google_project_iam_member" "google_service_account_is_monitoring_agent" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.jss_pos.email}"
}

resource "google_project_iam_member" "google_service_account_is_logging_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.jss_pos.email}"
}

// Create a dedicated Virtual Private Cloud (VPC) network for this solution.
// This network will be used for any network scoped resources in GCP like the
// GKE cluster and any load balancers created by Kubernetes Services
resource "google_compute_network" "jss_pos" {
  depends_on              = [module.enable_google_apis]
  project                 = var.project_id
  name                    = "jss-pos-${var.resource_name_suffix}"
  auto_create_subnetworks = true
}

// A public external IP address that will be statically attached to the
// Loadbalancer type Kubernetes Service created for the solution
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
  name                = "jss-pos-cluster-${var.resource_name_suffix}"
  project             = var.project_id
  location            = var.region
  network             = google_compute_network.jss_pos.id
  enable_autopilot    = true
  resource_labels     = var.labels
  deletion_protection = false

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

resource "google_project_iam_member" "jss_pos_role_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.jss_pos.email}"
}

resource "google_project_iam_member" "jss_pos_role_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.jss_pos.email}"
}

resource "google_project_iam_member" "jss_pos_role_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.jss_pos.email}"
}

resource "google_project_iam_member" "jss_pos_role_stackdriver_writer" {
  project = var.project_id
  role    = "roles/stackdriver.resourceMetadata.writer"
  member  = "serviceAccount:${google_service_account.jss_pos.email}"
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
  depends_on   = [module.enable_google_apis]
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
  depends_on = [
    google_container_cluster.jss_pos,
    google_spanner_database.jss_pos,
    google_compute_address.jss_pos,
  ]
  name    = "jss-point-of-sale"
  chart   = "${path.module}/charts"
  timeout = 600
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
