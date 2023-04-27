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

variable "region" {
  description = "The region of the Cloud SQL resource."
  type        = string
}

variable "private_network_id" {
  description = "VPC network"
  type        = string
}

variable "sql_user_password" {
  description = "Default password for user 'jss-pos-user'"
  type        = string
}

variable "availability_type" {
  description = "The availability type of the Cloud SQL instance, high availability (REGIONAL) or single zone (ZONAL)."
  type        = string
  validation {
    condition     = contains(["REGIONAL", "ZONAL"], var.availability_type)
    error_message = "Allowed values for type are \"REGIONAL\", \"ZONAL\"."
  }
}

variable "resource_name_suffix" {
  type        = string
  default     = "1"
  description = <<EOT
  Optional string added to the end of resource names, allowing project reuse.
  This should be short and only contain dashes, lowercase letters, and digits.
  It shoud not end with a dash.
  EOT
}
