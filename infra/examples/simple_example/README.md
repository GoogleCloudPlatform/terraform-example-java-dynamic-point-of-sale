# Simple Example

This is the most basic example for using the terraform based installation of the
`Dynamic Java Application on GKE` Jump start solution.

## Inputs

| Name        | Description             | Type     | Default | Required |
| ----------- | ----------------------- | -------- | ------- | :------: |
| project\_id | Google Cloud Project ID | `string` | n/a     |   yes    |

## Quickstart

To provision this example, run the following from within this directory:

0. `terraform init` to download the plugins
0. `terraform plan -var 'project_id=my-project-id'` to see the infrastructure plan (where your `my-project-id` is your Google Cloud project ID)
0. `terraform apply -var 'project_id=my-project-id'` to apply the infrastructure build
0. `terraform destroy -var 'project_id=my-project-id'` to destroy the built infrastructure

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project\_id | Google Cloud Project ID | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| neos\_toc\_url | n/a |
| pos\_application\_url | n/a |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
