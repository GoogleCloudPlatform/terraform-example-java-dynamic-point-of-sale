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

// Enable access to the configuration of the Google Cloud provider.
data "google_client_config" "default" {}

provider "helm" {
  kubernetes {
    host                   = var.cluster_endpoint
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  }
}

resource "helm_release" "jss_point_of_sale" {
  name  = "jss-point-of-sale"
  chart = "${path.module}/pos-charts"
  values = [
    file("${path.module}/pos-charts/values.yaml"),
  ]

  dynamic "set" {
    for_each = var.entries == null ? [] : var.entries
    iterator = entry
    content {
      name  = entry.value.name
      value = entry.value.value
    }
  }

  dynamic "set_sensitive" {
    for_each = var.secret_entries == null ? [] : var.secret_entries
    iterator = secret_entry
    content {
      name  = secret_entry.value.name
      value = secret_entry.value.value
    }
  }
}
