# Important: No Secret Configuration Needed in Seqera!

## You Don't Need to Create Secrets in Seqera

The workflow **automatically retrieves** the secret from Google Secret Manager at runtime. You do **NOT** need to:
- ❌ Create secrets in Seqera's UI
- ❌ Configure secrets in Seqera's secret management
- ❌ Add secrets to the pipeline configuration

## How It Works

1. **Secret already exists** in Google Secret Manager: `basespace-api-key`
2. **Workflow retrieves it automatically** when the process runs using:
   ```bash
   gcloud secrets versions access latest --secret="basespace-api-key"
   ```
3. **No Seqera configuration needed** - just ensure your service account has permission

## What You Need to Do

### Step 1: Verify Service Account Permission

The **only** thing you need to ensure is that your compute environment's service account can **read** the existing secret:

```bash
# Get your service account from Seqera compute environment settings
export SERVICE_ACCOUNT="your-service-account@asu-ap-gap-data-opstest-18c2.iam.gserviceaccount.com"

# Grant read permission to the existing secret
gcloud secrets add-iam-policy-binding basespace-api-key \
  --project=asu-ap-gap-data-opstest-18c2 \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/secretmanager.secretAccessor"
```

### Step 2: Add Pipeline in Seqera (No Secret Configuration)

1. **Go to**: Seqera Platform → Your Workspace → Pipelines
2. **Click**: "Add Pipeline" → "From Git Repository"
3. **Enter**:
   - Repository: `https://github.com/tstafford-burwood/APGAP-BaseSpace-Test.git`
   - Branch: `theo-test`
4. **Click "Add"** - that's it!

**Do NOT**:
- Go to any "Secrets" section
- Try to create or configure secrets
- Add secret references in pipeline settings

### Step 3: Launch Pipeline

1. **Click "Launch"** on your pipeline
2. **Select** your compute environment
3. **Verify parameters** (they reference the secret name, not the secret value):
   ```json
   {
     "basespace_secret_name": "basespace-api-key",
     "gcp_project": "asu-ap-gap-data-opstest-18c2"
   }
   ```
4. **Launch** - the workflow will retrieve the secret automatically at runtime

## Troubleshooting Permission Errors

If you're getting permission errors, it's likely one of these:

### Error: "Permission denied" when adding pipeline

**This shouldn't happen** - adding a pipeline doesn't require secret permissions. If you see this:
- Make sure you're not trying to create secrets in Seqera
- Skip any "Secrets" or "Credentials" configuration steps
- Just add the pipeline from Git repository

### Error: "Permission denied" when pipeline runs

This means the service account can't read the secret. Fix it:

```bash
# Check current permissions
gcloud secrets get-iam-policy basespace-api-key \
  --project=asu-ap-gap-data-opstest-18c2

# Add permission if missing
gcloud secrets add-iam-policy-binding basespace-api-key \
  --project=asu-ap-gap-data-opstest-18c2 \
  --member="serviceAccount:YOUR_SERVICE_ACCOUNT" \
  --role="roles/secretmanager.secretAccessor"
```

## Summary

✅ **Do**: Add pipeline from Git, launch with parameters  
❌ **Don't**: Create or configure secrets in Seqera UI  
✅ **Verify**: Service account has `secretmanager.secretAccessor` role on the existing secret

The secret retrieval happens **inside the container at runtime** - Seqera never sees or needs to know about the secret value!

