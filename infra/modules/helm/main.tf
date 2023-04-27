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

resource "helm_release" "jss_point_of_sale" {
  name  = "jss-point-of-sale"
  chart = "${path.module}/charts"
  values = [
    file("${path.module}/charts/values.yaml"),
  ]

  dynamic "set" {
    for_each = var.helm_values == null ? [] : var.helm_values
    iterator = entry
    content {
      name  = entry.value.name
      value = entry.value.value
    }
  }

  dynamic "set_sensitive" {
    for_each = var.helm_secret_values == null ? [] : var.helm_secret_values
    iterator = secret_entry
    content {
      name  = secret_entry.value.name
      value = secret_entry.value.value
    }
  }
}