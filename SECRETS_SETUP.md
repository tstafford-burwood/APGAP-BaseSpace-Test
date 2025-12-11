# Secrets Manager Setup Guide

## Step 1: Store BaseSpace Access Token in Google Secret Manager

### Get your BaseSpace Access Token

1. **Option A: From existing BaseSpace CLI config**
   ```bash
   # If you have bs CLI installed locally and authenticated
   cat ~/.basespace/default.cfg
   # Look for the "access-token" field
   ```

2. **Option B: Generate new token via BaseSpace API**
   - Go to https://developer.basespace.illumina.com/
   - Create an app and generate an access token
   - Or use the BaseSpace web interface to generate a personal access token

### Store in Google Secret Manager

```bash
# Set your project ID
export PROJECT_ID="asu-ap-gap-data-opstest-18c2"

# Create the secret (if it doesn't exist)
echo -n "YOUR_BASESPACE_ACCESS_TOKEN" | gcloud secrets create basespace-access-token \
  --project=$PROJECT_ID \
  --data-file=-

# Or update existing secret
echo -n "YOUR_BASESPACE_ACCESS_TOKEN" | gcloud secrets versions add basespace-access-token \
  --project=$PROJECT_ID \
  --data-file=-
```

### Grant access to the secret

```bash
# Grant access to the service account used by your compute environment
# Replace SERVICE_ACCOUNT_EMAIL with your actual service account
gcloud secrets add-iam-policy-binding basespace-access-token \
  --project=$PROJECT_ID \
  --member="serviceAccount:SERVICE_ACCOUNT_EMAIL" \
  --role="roles/secretmanager.secretAccessor"
```

