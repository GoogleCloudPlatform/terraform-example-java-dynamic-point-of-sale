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

resource "google_secret_manager_secret" "sql_password" {
  secret_id = "jss-pos-db-pwd-${var.resource_name_suffix}"
  project   = var.project_id

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "sql_password" {
  secret_data = var.sql_user_password
  secret      = google_secret_manager_secret.sql_password.id
  enabled     = true
}

resource "google_secret_manager_secret_iam_member" "sql_password" {
  project   = google_secret_manager_secret.sql_password.project
  secret_id = google_secret_manager_secret.sql_password.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.service_account}"
}
