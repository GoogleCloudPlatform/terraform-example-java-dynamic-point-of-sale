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

resource "google_container_cluster" "jss_pos" {
  name             = "jss-pos-cluster-${var.name_suffix}"
  project          = var.project_id
  location         = var.region
  network          = var.network
  enable_autopilot = true
  resource_labels  = var.labels

  cluster_autoscaling {
    auto_provisioning_defaults {
      service_account = var.google_service_account.email
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
    name      = var.k8s_service_account_name
    namespace = var.k8s_namespace
    annotations = {
      "iam.gke.io/gcp-service-account" = var.google_service_account.email
    }
  }
}

resource "google_service_account_iam_member" "jss_poss_impersonate_google_sa" {
  depends_on         = [kubernetes_service_account.jss_pos]
  service_account_id = var.google_service_account.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.k8s_namespace}/${var.k8s_service_account_name}]"
}
