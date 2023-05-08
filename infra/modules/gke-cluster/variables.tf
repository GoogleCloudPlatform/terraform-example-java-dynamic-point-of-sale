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

variable "project_id" {
  type        = string
  description = "The Google Cloud project ID."
}

variable "region" {
  type        = string
  description = "The Google Cloud region where resources are provisioned."
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = <<EOT
    A set of key/value label pairs to assign to the Google Kubernetes Engine
    cluster. These labels are used by the blueprints controller to filter this
    resource if it is created as part of the blueprints controller framework.
    EOT
}

variable "name_suffix" {
  type        = string
  description = <<EOT
  Optional string added to the end of resource names, allowing project reuse.
  This should be short and only contain dashes, lowercase letters, and digits.
  It shoud not end with a dash.
  EOT
}

variable "network" {
  type        = string
  description = "Google Cloud VPC network in which the cluster will be created"
}

variable "google_service_account" {
  type        = string
  description = <<EOT
  Google Service Account to associate to the nodes of the Google Kubernetes
  Engine cluster
  EOT
}

variable "k8s_service_account_name" {
  type        = string
  description = <<EOF
  Name of the Kubernetes service account that will be created to associate with
  the workload Pods. This service account will be bound as the WorkloadIdentity
  account against the Google service account.
  EOF
}

variable "k8s_namespace" {
  type        = string
  description = <<EOT
  The namespace in which the Kubernetes service account will be created
  EOT
}
