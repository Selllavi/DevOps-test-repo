### Weather Application

Application could be used to pick up weather in Moscow city.
````
/ping - return PONG in HTML format, status code 200 OK  
/ - return current weather in Moscow, Russia in HTML format
/health - return status code 200, in JSON format  
````

Project contains:
* `app-code` - code of application written on Go and Dockerfile for its containerization.
* `docs` - docs folder
* `helm-charts` - helm chars on Helm 3 which could be used for installation of app on Kubernetes
* `terraform`
  Terraform script for provisioning all resources needed for EKS and EKS itself, 
  creating AWS CodePipeline and AWS CodeBuild.
  Terraform stages:
  1) Bootstrap cluster:
  - VPC creation
  - Private/Public subnets creation
  - Security Groups creation
  - Creation of Routing tables
  - Creation of NAT GW
  - Provision above it EKS cluster (1 node t3.small)
  - Provision Nginx ingress controller to EKS
  - Creation of NLB
  - Creation of External DNS
  2) Creation AWS CodePipeline:
  - creation of ECR for docker images and helm packages
  - creation AWS CodeBuild entity
  - creation AWS CodePipeline entity
  - creation GitHub WebHook to trigger CodePipeline

AWS CodePipeline:
  * Source stage
    - collect source code from GitHub repo
  * Build stage
    - build docker image and save it to ECR
    - package helm release and save it to ECR
    - install helm release on EKS
  
To trigger AWS CodePipeline push something into repository.

# Terraform
**Before use**:
Change `terraform/terraform.tfvars` to your needs.
Do not forget to change YOUR_TOKEN to real GitHub token.

**How to use**:
````
cd terraform
terraform init
terraform plan
terraform apply
````
After installation, you will see output
Execute command to update your kubectl:
````
aws eks --region eu-west-1 update-kubeconfig --name <cluster-eks>
````
where `<cluster-eks>` is value from output of terraform `cluster_id`.
````
Apply complete! Resources: 95 added, 0 changed, 0 destroyed.

Outputs:

cluster_endpoint = "https://04A6681F427A1C5FE7DBF320E093BA9B.gr7.eu-west
-1.eks.amazonaws.com"
cluster_id = "cluster-eks-nD9vovKY"
````

**Post use**:
After usage do not forget to clean all resources with
````
terraform destroy
````
# App code
How to use locally:
````
cd app-code
docker build . -t docker-weather:v1.0
docker run -p 8080:8080 -e API_KEY=<your apikey> docker-weather:v1.0
````
where `<your apikey>` is correct value from service https://openweathermap.org/current

# Helm Chart
How to use locally:
````
cd helm-charts
helm upgrade --install <Helm Release Name> .
````
where `<Helm Release Name>` is name of helm release which will be visible with `helm list` command.
