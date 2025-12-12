# First Image Setup for bs-gcs2 Repository

## Step 1: Create the Repository (Required First Time)

Since this is your first image in `bs-gcs2`, you need to create the repository first:

```bash
gcloud artifacts repositories create bs-gcs2 \
  --repository-format=docker \
  --location=us-central1 \
  --project=asu-ap-gap-data-opstest-18c2 \
  --description="BaseSpace to GCS transfer container images"
```

**Expected output:**
```
Created repository [bs-gcs2].
Location: us-central1
Format: DOCKER
```

## Step 2: Verify Repository Was Created

```bash
gcloud artifacts repositories list \
  --location=us-central1 \
  --project=asu-ap-gap-data-opstest-18c2
```

You should see `bs-gcs2` in the list.

## Step 3: Configure Docker Authentication

```bash
gcloud auth configure-docker us-central1-docker.pkg.dev
```

## Step 4: Build Your First Image

```bash
cd /Users/tstafford/Documents/APGAP-BaseSpace-Test/basespace-gcs-nf

docker build . --platform linux/amd64 \
  -t us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client:latest
```

## Step 5: Push Your First Image

```bash
docker push us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client:latest
```

## Step 6: Verify Your First Image

```bash
gcloud artifacts docker images list \
  us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client
```

**Expected output:**
```
IMAGE: us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client
DIGEST: sha256:...
CREATE_TIME: [timestamp]
UPDATE_TIME: [timestamp]
TAGS: latest
```

## Complete Command Sequence

Here's everything in order:

```bash
# 1. Set project
gcloud config set project asu-ap-gap-data-opstest-18c2

# 2. Create repository (FIRST TIME ONLY)
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

## Notes

- **Repository creation is a one-time step** - after this, you can just build and push
- **The repository will be empty** until you push your first image
- **Future builds** only need steps 4-6 (build and push)

After your first successful push, the repository will contain your image and be ready for use in Seqera!

