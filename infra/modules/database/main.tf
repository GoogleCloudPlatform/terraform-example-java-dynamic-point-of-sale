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

resource "google_compute_global_address" "sql" {
  name          = "jss-pos-db-address-${var.resource_name_suffix}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 20
  network       = var.private_network_id
}

resource "google_service_networking_connection" "private_vpc" {
  network = var.private_network_id
  service = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [
    google_compute_global_address.sql.name,
  ]
}

resource "google_sql_database_instance" "jss_pos_db" {
  name             = "jss-pos-${var.region}-db-${var.resource_name_suffix}"
  database_version = "MYSQL_8_0"
  region           = var.region
  settings {
    availability_type = var.availability_type
    backup_configuration {
      enabled            = true
      binary_log_enabled = true
    }
    tier      = "db-custom-2-4096"
    disk_type = "PD_SSD"
    disk_size = 20
    ip_configuration {
      private_network = var.private_network_id
      ipv4_enabled    = false
    }
  }

  deletion_protection = false
  depends_on          = [google_service_networking_connection.private_vpc]
}

resource "google_sql_database" "jss_pos_db" {
  name      = "jss-pos-db-${var.resource_name_suffix}"
  charset   = "utf8"
  collation = "utf8_general_ci"
  instance  = google_sql_database_instance.jss_pos_db.name
}

resource "google_sql_user" "jss_pos_user" {
  name     = "jss-pos-user"
  instance = google_sql_database_instance.jss_pos_db.name
  password = var.sql_user_password
}


