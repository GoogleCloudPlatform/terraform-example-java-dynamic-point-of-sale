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

output "db_ip" {
  description = "The IPv4 address assigned for the master database instance"
  value       = google_sql_database_instance.jss_pos_db.private_ip_address
}

output "db_user_name" {
  description = "SQL username for the database"
  value       = google_sql_user.jss_pos_user.name
}
