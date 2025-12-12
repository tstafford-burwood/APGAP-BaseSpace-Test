# Setting Up bs-gcs2 Artifact Registry Repository

## Create the Artifact Registry Repository

Before building and pushing the image, create the new repository:

```bash
export PROJECT_ID="asu-ap-gap-data-opstest-18c2"
export REGION="us-central1"
export REPO_NAME="bs-gcs2"

# Create the Artifact Registry repository
gcloud artifacts repositories create $REPO_NAME \
  --repository-format=docker \
  --location=$REGION \
  --project=$PROJECT_ID \
  --description="BaseSpace to GCS transfer container images"
```

## Build and Push the Image

After creating the repository, build and push your image:

```bash
# Configure Docker to use gcloud as a credential helper
gcloud auth configure-docker us-central1-docker.pkg.dev

# Build the image
docker build . --platform linux/amd64 \
  -t us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client:latest

# Push to Artifact Registry
docker push us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client:latest
```

## Verify the Image

```bash
# List images in the repository
gcloud artifacts docker images list \
  us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client

# Test pulling the image
docker pull us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client:latest
```

## Service Account Permissions

Ensure your compute environment's service account has access to pull from the new repository:

```bash
export SERVICE_ACCOUNT="your-service-account@${PROJECT_ID}.iam.gserviceaccount.com"

# Grant Artifact Registry Reader role
gcloud artifacts repositories add-iam-policy-binding $REPO_NAME \
  --location=$REGION \
  --project=$PROJECT_ID \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/artifactregistry.reader"
```

## Updated Image Path

All code now references:
```
us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client:latest
```

This is separate from the original `bs-gcs` repository, so it won't affect other developers' work.

