# Quick Start: Seqera Pipeline Setup

## Prerequisites
- ✅ Secret: `basespace-api-key` in Secret Manager
- ✅ Workspace and Compute Environment in Seqera
- ✅ Service account with Secret Manager access

## Steps

### 1. Add Pipeline
- Seqera Platform → Workspace → Pipelines → Add Pipeline
- Repository: `https://github.com/tstafford-burwood/APGAP-BaseSpace-Test.git`
- Branch: `theo-test`
- Name: "BaseSpace to GCS Transfer"

### 2. Verify Compute Environment
- Service account has `roles/secretmanager.secretAccessor`
- Can access container: `us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client:latest`
- Work directory set to GCS bucket

### 3. Launch Pipeline
- Pipeline → Launch
- Compute Environment: Select your GCP environment
- Parameters (verify):
  - `basespace_secret_name`: `basespace-api-key`
  - `gcp_project`: `asu-ap-gap-data-opstest-18c2`
- Click "Launch"

### 4. Monitor
- View run in "Runs" tab
- Check process logs for:
  - Secret retrieval
  - BaseSpace authentication
  - File download/upload progress
- Verify files in GCS: `gs://a-test-output/`

## Troubleshooting

**Secret access denied?**
```bash
gcloud secrets add-iam-policy-binding basespace-api-key \
  --project=asu-ap-gap-data-opstest-18c2 \
  --member="serviceAccount:YOUR_SERVICE_ACCOUNT" \
  --role="roles/secretmanager.secretAccessor"
```

**BaseSpace auth failed?**
- Verify API key in Secret Manager is valid
- Test locally: `export BASESPACE_API_KEY="key" && bs auth whoami`

**Container not found?**
- Verify image exists and service account has Artifact Registry access

