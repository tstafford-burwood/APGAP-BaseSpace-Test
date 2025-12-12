# Step-by-Step: Build and Push Image to bs-gcs2 Repository

## Prerequisites

- Docker installed and running
- `gcloud` CLI installed and authenticated
- Access to project: `asu-ap-gap-data-opstest-18c2`

## Step 1: Authenticate with Google Cloud

```bash
# Login to gcloud (if not already logged in)
gcloud auth login

# Set your project
gcloud config set project asu-ap-gap-data-opstest-18c2

# Verify you're authenticated
gcloud auth list
```

## Step 2: Create the Artifact Registry Repository (First Time Only)

If the repository doesn't exist yet, create it:

```bash
# Create the repository
gcloud artifacts repositories create bs-gcs2 \
  --repository-format=docker \
  --location=us-central1 \
  --project=asu-ap-gap-data-opstest-18c2 \
  --description="BaseSpace to GCS transfer container images"
```

**Expected output:**
```
Created repository [bs-gcs2].
```

**If repository already exists**, you'll see:
```
ERROR: (gcloud.artifacts.repositories.create) Repository bs-gcs2 already exists
```
This is fine - you can skip to Step 3.

## Step 3: Configure Docker Authentication

Configure Docker to use gcloud credentials for Artifact Registry:

```bash
gcloud auth configure-docker us-central1-docker.pkg.dev
```

**Expected output:**
```
Adding credentials for: us-central1-docker.pkg.dev
After update, the following will be written to your Docker config
...
```

## Step 4: Navigate to Your Project Directory

```bash
cd /Users/tstafford/Documents/APGAP-BaseSpace-Test/basespace-gcs-nf
```

## Step 5: Build the Docker Image

Build the image with the correct tag:

```bash
docker build . --platform linux/amd64 \
  -t us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client:latest
```

**What this does:**
- Builds the image from the Dockerfile in the current directory
- Uses `--platform linux/amd64` for compatibility (required on Mac M1/M2)
- Tags it with the full Artifact Registry path

**Expected output:**
```
[+] Building ...
...
Successfully built [image-id]
Successfully tagged us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client:latest
```

**Build time:** This may take a few minutes the first time.

## Step 6: Verify the Image Was Built

Check that the image exists locally:

```bash
docker images | grep bs-gcs2
```

**Expected output:**
```
us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client   latest   [image-id]   [time]   [size]
```

## Step 7: Push the Image to Artifact Registry

Push the image to the repository:

```bash
docker push us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client:latest
```

**Expected output:**
```
The push refers to repository [us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client]
...
latest: digest: sha256:... size: ...
```

**Push time:** This may take a few minutes depending on image size and network speed.

## Step 8: Verify the Image in Artifact Registry

Verify the image was pushed successfully:

```bash
gcloud artifacts docker images list \
  us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client
```

**Expected output:**
```
IMAGE: us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client
DIGEST: sha256:...
CREATE_TIME: ...
UPDATE_TIME: ...
TAGS: latest
```

## Step 9: Test Pulling the Image (Optional)

Test that you can pull the image back:

```bash
docker pull us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client:latest
```

This verifies the image is accessible.

## Troubleshooting

### Error: "Repository not found"
**Solution:** Make sure you created the repository in Step 2, or verify the repository name is correct.

### Error: "Permission denied"
**Solution:** 
```bash
# Verify you have the right permissions
gcloud projects get-iam-policy asu-ap-gap-data-opstest-18c2 \
  --flatten="bindings[].members" \
  --filter="bindings.members:$(gcloud config get-value account)"

# Or grant yourself the necessary role
gcloud artifacts repositories add-iam-policy-binding bs-gcs2 \
  --location=us-central1 \
  --project=asu-ap-gap-data-opstest-18c2 \
  --member="user:$(gcloud config get-value account)" \
  --role="roles/artifactregistry.writer"
```

### Error: "Cannot connect to Docker daemon"
**Solution:** Make sure Docker Desktop is running.

### Error: "unauthorized: authentication required"
**Solution:** Re-run Step 3 to configure Docker authentication.

## Quick Reference: All Commands in One Block

```bash
# 1. Set project
gcloud config set project asu-ap-gap-data-opstest-18c2

# 2. Create repository (if needed)
gcloud artifacts repositories create bs-gcs2 \
  --repository-format=docker \
  --location=us-central1 \
  --project=asu-ap-gap-data-opstest-18c2 \
  --description="BaseSpace to GCS transfer container images"

# 3. Configure Docker
gcloud auth configure-docker us-central1-docker.pkg.dev

# 4. Navigate to project
cd /Users/tstafford/Documents/APGAP-BaseSpace-Test/basespace-gcs-nf

# 5. Build image
docker build . --platform linux/amd64 \
  -t us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client:latest

# 6. Push image
docker push us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client:latest

# 7. Verify
gcloud artifacts docker images list \
  us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client
```

## Next Steps

After successfully pushing the image:

1. **Grant access to your service account** (for Seqera compute environment):
   ```bash
   export SERVICE_ACCOUNT="your-service-account@asu-ap-gap-data-opstest-18c2.iam.gserviceaccount.com"
   
   gcloud artifacts repositories add-iam-policy-binding bs-gcs2 \
     --location=us-central1 \
     --project=asu-ap-gap-data-opstest-18c2 \
     --member="serviceAccount:${SERVICE_ACCOUNT}" \
     --role="roles/artifactregistry.reader"
   ```

2. **Launch your pipeline** in Seqera - it will now use the new image!

