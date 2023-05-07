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
    "CREATE TABLE t1 (t1 INT64 NOT NULL,) PRIMARY KEY(t1)",
    "CREATE TABLE t2 (t2 INT64 NOT NULL,) PRIMARY KEY(t2)",
  ]
}
