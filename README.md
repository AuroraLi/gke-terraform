# Sample Terraform for GKE

This is a sample Terraform code to manage GKE clusters using Cloud Build. 

Cloud Build includes steps that:
- Create/check a backend storage for Terraform states
- Initialize Terraform workspace
- Plan Terraform
- Apply Terraform 

Terraform includes:
- Create a GCP VPC and a subnetwork
- Create regional GKE cluster
- Create regional GKE cluster node pool
- Enable [Workload Identity](https://cloud.google.com/blog/products/containers-kubernetes/introducing-workload-identity-better-authentication-for-your-gke-applications)



## How to use
Enable required APIs:
```
export PROJECT_ID=$(gcloud config get-value project)
gcloud services enable --project ${PROJECT_ID} \
    cloudresourcemanager.googleapis.com \
    compute.googleapis.com \
    container.googleapis.com \
    cloudbuild.googleapis.com \
    stackdriver.googleapis.com \
    sourcerepo.googleapis.com
```

Assign Permissions to Cloud Build
```
CLOUDBUILD_SA=$(gcloud projects describe ${PROJECT_ID} --format='value(projectNumber)')@cloudbuild.gserviceaccount.com 
gcloud projects add-iam-policy-binding ${PROJECT_ID} --member serviceAccount:${CLOUDBUILD_SA} --role roles/owner
gcloud projects add-iam-policy-binding ${PROJECT_ID} --member serviceAccount:${CLOUDBUILD_SA} --role roles/iam.serviceAccountTokenCreator

```

Clone this repo and manually trigger Cloud Build:
```
git clone https://github.com/AuroraLi/gke-terraform.git && cd gke-terraform
gcloud builds submits
```

### Clean up
To clean up, run the destroy Cloud Build:
```
gcloud builds submits --config destroy.yaml
```

## Best Practices
