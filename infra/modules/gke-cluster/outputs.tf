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

output "cluster_endpoint" {
  value       = google_container_cluster.jss_pos.endpoint
  description = "The publicly reachable endpoint for the cluster's API server"
}

output "cluster_ca_certificate" {
  value       = google_container_cluster.jss_pos.master_auth[0].cluster_ca_certificate
  description = <<EOF
  The CA certificate to be used by clients to authenticate the API server
  EOF
  sensitive   = true
}
