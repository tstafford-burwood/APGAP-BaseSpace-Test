# Step-by-Step Guide: Implementing BaseSpace to GCS Pipeline in Seqera Platform

## Prerequisites Checklist

Before starting, ensure you have:
- ✅ Secret created in Google Secret Manager (`basespace-api-key`)
- ✅ Workspace created in Seqera Platform
- ✅ Compute Environment configured (GCP-based recommended)
- ✅ Service account with Secret Manager access permissions
- ✅ Container image accessible: `us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client:latest`

---

## Step 1: Verify Compute Environment Configuration

### 1.1 Check Service Account Permissions

Your compute environment's service account needs these permissions:

1. **Go to**: Seqera Platform → Your Workspace → Compute Environments
2. **Select** your compute environment
3. **Note the Service Account** email address
4. **Verify permissions** in Google Cloud Console:

```bash
# In Google Cloud Console or gcloud CLI, verify the service account has:
# - roles/secretmanager.secretAccessor (for Secret Manager)
# - roles/storage.objectCreator (for GCS uploads)
# - roles/artifactregistry.reader (to pull container image)
```

If permissions are missing, grant them:

```bash
export PROJECT_ID="asu-ap-gap-data-opstest-18c2"
export SERVICE_ACCOUNT="your-service-account@${PROJECT_ID}.iam.gserviceaccount.com"
export SECRET_NAME="basespace-api-key"

# Grant Secret Manager access
gcloud secrets add-iam-policy-binding $SECRET_NAME \
  --project=$PROJECT_ID \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/secretmanager.secretAccessor"

# Grant GCS access (if not already granted)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/storage.objectCreator"
```

### 1.2 Verify Container Image Access

Ensure your compute environment can pull the container:

```bash
# Test from a GCP VM or Cloud Shell
gcloud auth configure-docker us-central1-docker.pkg.dev
docker pull us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client:latest
```

---

## Step 2: Add Pipeline to Seqera Platform

### 2.1 Add Pipeline from Git Repository

1. **Navigate to**: Seqera Platform → Your Workspace → Pipelines
2. **Click**: "Add Pipeline" or "+" button
3. **Select**: "From Git Repository"
4. **Enter Repository URL**:
   ```
   https://github.com/tstafford-burwood/APGAP-BaseSpace-Test.git
   ```
5. **Select Branch**: `theo-test`
6. **Pipeline Name**: "BaseSpace to GCS Transfer" (or your preferred name)
7. **Description**: "Transfers files from Illumina BaseSpace to Google Cloud Storage"
8. **Click**: "Add" or "Create"

### 2.2 Verify Pipeline Configuration

1. **Click** on your newly added pipeline
2. **Verify** the pipeline details:
   - Repository URL is correct
   - Branch is `theo-test`
   - Main script path: `main.nf` (should be auto-detected)
   - Config file: `nextflow.config` (should be auto-detected)

---

## Step 3: Configure Pipeline Parameters

### 3.1 Set Default Parameters

1. **In the Pipeline page**, click on **"Parameters"** or **"Settings"**
2. **Configure the following parameters**:

| Parameter | Value | Description |
|-----------|-------|-------------|
| `basespace_secret_name` | `basespace-api-key` | Name of secret in Secret Manager |
| `gcp_project` | `asu-ap-gap-data-opstest-18c2` | GCP project ID |
| `outdir` | `gs://your-bucket/results` | GCS bucket for output (optional) |

**Note**: These can also be overridden when launching the pipeline.

### 3.2 Update Input Data (Optional)

The workflow currently has hardcoded test data. To use different files:

**Option A: Modify in Seqera Launch Form**
- When launching, you can override the channel data via parameters (requires workflow modification)

**Option B: Use Input File**
- Create a CSV file with BaseSpace file IDs and GCS paths
- Modify workflow to read from file (future enhancement)

For now, the test data in `main.nf` will work for initial testing.

---

## Step 4: Configure Compute Environment Settings

### 4.1 Verify Compute Environment

1. **Go to**: Compute Environments
2. **Select** your GCP compute environment
3. **Verify**:
   - **Region**: Should match your GCS bucket region (e.g., `us-central1`)
   - **Service Account**: Should have Secret Manager permissions
   - **Work Directory**: Should be a GCS bucket path (e.g., `gs://your-bucket/work`)
   - **Container Registry**: Should have access to `us-central1-docker.pkg.dev`

### 4.2 Set Environment Variables (Optional)

If you prefer to use environment variables instead of retrieving secrets in the script:

1. **In Compute Environment settings**, go to **"Environment Variables"**
2. **Add** (if using this approach):
   - **Name**: `BASESPACE_API_KEY`
   - **Value**: Reference to Secret Manager (if Seqera supports it)
   - **OR**: Leave empty and let the workflow retrieve it

**Note**: Our current implementation retrieves the secret in the workflow script, so this step is optional.

---

## Step 5: Launch the Pipeline

### 5.1 Create a Launch Configuration

1. **Go to**: Your Pipeline → Click **"Launch"** or **"Run"**
2. **Select Compute Environment**: Choose your GCP compute environment
3. **Review Parameters**:
   - `basespace_secret_name`: `basespace-api-key`
   - `gcp_project`: `asu-ap-gap-data-opstest-18c2`
   - Verify these match your setup

### 5.2 Configure Launch Options

1. **Run Name**: "BaseSpace Transfer Test" (or descriptive name)
2. **Compute Environment**: Select your configured environment
3. **Work Directory**: Should be auto-filled from compute environment
4. **Resume**: Check if you want to enable resume functionality
5. **Nextflow Options**: 
   - `-resume` (if you want to resume failed runs)
   - `-with-report` (for detailed reports)
   - `-with-trace` (for execution tracing)

### 5.3 Launch the Pipeline

1. **Click**: "Launch" or "Run"
2. **Monitor**: The pipeline will start and you'll see it in the "Runs" tab

---

## Step 6: Monitor Pipeline Execution

### 6.1 View Run Details

1. **Go to**: Runs tab
2. **Click** on your running pipeline
3. **Monitor**:
   - **Status**: Should show "RUNNING" then "SUCCEEDED" or "FAILED"
   - **Logs**: Click on process to view logs
   - **Timeline**: See execution timeline

### 6.2 Check Process Logs

1. **Click** on the `TRANSFER_BS_TO_GCS` process
2. **View logs** to see:
   - Secret retrieval status
   - BaseSpace authentication verification
   - File download progress
   - GCS upload progress

### 6.3 Verify Outputs

1. **Check GCS bucket**: Verify files were uploaded to:
   - `gs://a-test-output/2025WW01450_S8_L001_R1_001.fastq.gz`
   - `gs://a-test-output/2025WW01450_S8_L001_R2_001.fastq.gz`

---

## Step 7: Troubleshooting Common Issues

### Issue 1: Secret Manager Access Denied

**Error**: `Permission denied` when accessing secret

**Solution**:
```bash
# Verify service account has permission
gcloud secrets get-iam-policy basespace-api-key \
  --project=asu-ap-gap-data-opstest-18c2

# Grant permission if missing
gcloud secrets add-iam-policy-binding basespace-api-key \
  --project=asu-ap-gap-data-opstest-18c2 \
  --member="serviceAccount:YOUR_SERVICE_ACCOUNT" \
  --role="roles/secretmanager.secretAccessor"
```

### Issue 2: Container Image Not Found

**Error**: `Failed to pull container image`

**Solution**:
1. Verify container exists: `gcloud artifacts docker images list us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2`
2. Grant Artifact Registry reader role to service account
3. Verify compute environment can access the registry

### Issue 3: BaseSpace Authentication Failed

**Error**: `BaseSpace authentication failed`

**Solution**:
1. Verify API key is valid in Secret Manager
2. Test API key locally: `export BASESPACE_API_KEY="your-key" && bs auth whoami`
3. Check API key hasn't expired or been revoked
4. Verify API key has necessary permissions in BaseSpace

### Issue 4: GCS Upload Failed

**Error**: `GCS upload failed`

**Solution**:
1. Verify service account has `storage.objectCreator` role
2. Check GCS bucket exists and is accessible
3. Verify bucket path is correct (no typos)
4. Check bucket permissions

### Issue 5: BaseSpace File Not Found

**Error**: `Failed to get file metadata`

**Solution**:
1. Verify BaseSpace file ID is correct
2. Check API key has access to the file/project
3. Verify file hasn't been deleted or moved
4. Check BaseSpace project permissions

---

## Step 8: Customize for Production Use

### 8.1 Parameterize Input Data

To make the workflow more flexible, you can:

1. **Create a CSV input file**:
   ```csv
   basespace_file_id,gcs_output_path
   42274677162,gs://a-test-output/file1.fastq.gz
   42274677163,gs://a-test-output/file2.fastq.gz
   ```

2. **Modify workflow** to read from CSV (future enhancement)

### 8.2 Add Error Notifications

Configure Seqera to send notifications:
- On pipeline completion
- On pipeline failure
- Via email, Slack, or webhook

### 8.3 Set Up Scheduled Runs

1. **Go to**: Pipeline → Schedules
2. **Create schedule** for regular transfers
3. **Configure**: Frequency, parameters, compute environment

---

## Quick Reference: Launch Command (CLI Alternative)

If using Seqera CLI (`tw`):

```bash
tw launch \
  --workspace "your-workspace" \
  --compute-env "your-compute-env" \
  --params-file params.json \
  https://github.com/tstafford-burwood/APGAP-BaseSpace-Test.git \
  --branch theo-test \
  --name "BaseSpace Transfer"
```

Where `params.json` contains:
```json
{
  "basespace_secret_name": "basespace-api-key",
  "gcp_project": "asu-ap-gap-data-opstest-18c2"
}
```

---

## Summary Checklist

- [ ] Compute environment configured with correct service account
- [ ] Service account has Secret Manager access
- [ ] Container image accessible
- [ ] Pipeline added from Git repository (`theo-test` branch)
- [ ] Parameters configured correctly
- [ ] Pipeline launched successfully
- [ ] Outputs verified in GCS bucket
- [ ] Logs reviewed for any issues

---

## Next Steps

After successful test run:
1. Update workflow to accept dynamic input (CSV or parameters)
2. Add more error handling and retry logic
3. Set up monitoring and alerts
4. Configure scheduled runs if needed
5. Document your specific use case and parameters

