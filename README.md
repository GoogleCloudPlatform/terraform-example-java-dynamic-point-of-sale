# Terraform Dynamic Java Application on GKE

This repository contains the Terraform and the Kubernetes YAML deployed by the Jump Start Solution (JSS) titled [Dynamic web application with Java](https://console.cloud.google.com/products/solutions/details/dynamic-java-web-application).
The source code for web application ("Point of Sale") deployed by this JSS can be found at [github.com/GoogleCloudPlatform/point-of-sale, in the jss-3.0 branch](https://github.com/GoogleCloudPlatform/point-of-sale/tree/jss-3.0).

## Quickstart

Try out the Terraform in this repository.

### Prerequisites

* The Terraform has only been tested on [Google Cloud Shell](https://cloud.google.com/shell).
* You environment will need:
    * `terraform`
    * `gcloud`
    * `kubectl`
    * `sed`

### Steps

#### 1. Clone this git repository.

```
git clone https://github.com/GoogleCloudPlatform/terraform-example-java-dynamic-point-of-sale
```

#### 2. Go into the `infra/` folder.

```
cd terraform-example-java-dynamic-point-of-sale/infra
```

#### 3. Run the Terraform.

```
terraform init
terraform apply -var 'project_id=MY_PROJECT_ID'
```

Replace `MY_PROJECT_ID` with your [Google Cloud Project](https://cloud.google.com/resource-manager/docs/creating-managing-projects) ID. We recommend creating a new project so you can easily clean up all resources by deleting the entire project.

You may need to type "Yes", when after you run `terraform apply`.

#### 4. Report any bugs as a GitHub Issue.

a. Search the [existing list of GitHub](https://github.com/GoogleCloudPlatform/terraform-example-java-dynamic-point-of-sale/issues?q=is%3Aissue).

b. If there isn't already a GitHub issue for your bug, [create a new GitHub issue](https://github.com/GoogleCloudPlatform/terraform-example-java-dynamic-point-of-sale/issues/new/choose).

#### 5. Get the IP address of the deployment.

TBD

## Contributing

If you would like to contribute to this repository, read [CONTRIBUTING](CONTRIBUTING.md).

Please note that this project is released with a Contributor Code of Conduct. By participating in
this project you agree to abide by its terms. See [Code of Conduct](CODE_OF_CONDUCT.md) for more
information.

## License

Apache 2.0 - See [LICENSE](LICENSE) for more information.
