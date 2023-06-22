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

output "neos_toc_url" {
  description = "Neos Tutorial URL"
  value       = "https://console.cloud.google.com/products/solutions/deployments?walkthrough_id=panels--sic--dynamic-java-web-app_toc"
}

output "pos_application_url" {
  description = "The public URL of the Point-of-sale application"
  value       = "http://${google_compute_address.jss_pos.address}"
}
