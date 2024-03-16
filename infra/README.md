# Dynamic Java Application on GKE

## Description

### Tagline

Point of sale website optimized to scale up quickly, N-tier dynamic webapps embedded in JVM containers.

### Detailed

This solution showcases an N-tier app hosted on GKE and backed by Spanner & Secret Manager as external services. The Vue.js front end is served from Spring Boot's embedded web servers.

The resources/services/activations/deletions that this module will create/trigger are:

- GKE
- Cloud Spanner
- Artifact Registry
- Cloud Build



<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| labels | A set of key/value label pairs to assign to the resources deployed by this<br>    blueprint. | `map(string)` | <pre>{<br>  "application": "point-of-sale",<br>  "description": "dynamic-java-application-gke",<br>  "jss": "up-2-2"<br>}</pre> | no |
| project\_id | The Google Cloud project ID. | `string` | n/a | yes |
| region | The Google Cloud region where resources are provisioned. | `string` | `"us-central1"` | no |
| resource\_name\_suffix | Optional string added to the end of resource names, allowing project reuse.<br>  This should be short and only contain dashes, lowercase letters, and digits.<br>  It shoud not end with a dash. | `string` | `"1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| neos\_toc\_url | Neos Tutorial URL |
| pos\_application\_url | The public URL of the Point-of-sale application |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Requirements

These sections describe requirements for using this module.

### Software

The following dependencies must be available:

- [Terraform](https://developer.hashicorp.com/terraform/downloads) v0.13
- [Terraform Provider for GCP](https://registry.terraform.io/providers/hashicorp/google/latest/docs) plugin v4.57

### Service Account

- roles/container.clusterAdmin
- roles/iam.serviceAccountUser
- roles/iam.serviceAccountAdmin
- roles/iam.workloadIdentityUser
- roles/spanner.admin
- roles/compute.networkAdmin


A service account with the following roles must be used to provision
the resources of this module:

### APIs

A project with the following APIs enabled must be used to host the
resources of this module:

- cloudbuild.googleapis.com
- iam.googleapis.com
- cloudresourcemanager.googleapis.com
- container.googleapis.com
- spanner.googleapis.com
- monitoring.googleapis.com
