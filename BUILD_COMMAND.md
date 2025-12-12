# Build and Push Docker Image to bs-gcs2 Repository

## Build Command

```bash
docker build . --platform linux/amd64 \
  -t us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client:latest
```

## Complete Build and Push Workflow

### Step 1: Build the Image

```bash
cd /Users/tstafford/Documents/APGAP-BaseSpace-Test/basespace-gcs-nf

docker build . --platform linux/amd64 \
  -t us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client:latest
```

### Step 2: Verify Image Was Built

```bash
docker images | grep bs-gcs2
```

### Step 3: Push to Artifact Registry

```bash
docker push us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client:latest
```

### Step 4: Verify in Artifact Registry

```bash
gcloud artifacts docker images list \
  us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client
```

## Prerequisites

Make sure you've:
1. ✅ Created the repository (if first time):
   ```bash
   gcloud artifacts repositories create bs-gcs2 \
     --repository-format=docker \
     --location=us-central1 \
     --project=asu-ap-gap-data-opstest-18c2
   ```

2. ✅ Configured Docker authentication:
   ```bash
   gcloud auth configure-docker us-central1-docker.pkg.dev
   ```

## Quick Reference

**Build only:**
```bash
docker build . --platform linux/amd64 \
  -t us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client:latest
```

**Build and push:**
```bash
docker build . --platform linux/amd64 \
  -t us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client:latest && \
docker push us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client:latest
```

