# API Key vs Access Token for BaseSpace Workflow

## Comparison: API Key vs Access Token

### API Key (Recommended for Your Use Case ✅)

**Advantages:**
- ✅ **Long-lived** - Doesn't expire automatically (or expires very infrequently)
- ✅ **Simpler** - Just set as environment variable, no OAuth flow needed
- ✅ **Better for automation** - Perfect for CI/CD, scheduled jobs, containerized workflows
- ✅ **No refresh logic** - Set it once and forget it
- ✅ **Easier to manage** - One credential to store in Secret Manager

**Disadvantages:**
- ⚠️ **Less secure if exposed** - Since it doesn't expire, if leaked it's valid until revoked
- ⚠️ **May have broader permissions** - Typically tied to your account, not scoped to specific apps

**Best for:** Automated pipelines, server-to-server communication, long-running processes

### Access Token (OAuth2)

**Advantages:**
- ✅ **More secure** - Short-lived, expires automatically
- ✅ **Fine-grained permissions** - Scoped to specific app permissions
- ✅ **User-specific** - Tied to user consent and authorization

**Disadvantages:**
- ❌ **Expires** - Requires token refresh logic
- ❌ **More complex** - Requires OAuth flow or token refresh mechanism
- ❌ **Not ideal for automation** - Needs periodic re-authentication

**Best for:** User-facing applications, temporary access, user-specific operations

## Recommendation: Use API Key

For your Nextflow workflow running in Seqera:
- **Automated execution** - No user interaction
- **Containerized environment** - Needs simple, static credentials
- **Long-running transfers** - Don't want tokens expiring mid-transfer
- **Simpler implementation** - Just set environment variable

## How BaseSpace CLI Handles Authentication

The BaseSpace CLI (`bs`) supports multiple authentication methods:

1. **API Key**: Set `BASESPACE_API_KEY` environment variable
2. **Access Token**: Set `BASESPACE_ACCESS_TOKEN` environment variable  
3. **Config file**: `~/.basespace/default.cfg` (not suitable for containers)

Both work the same way from the CLI perspective - just different environment variable names!

## Implementation with API Key

### Step 1: Create API Key in BaseSpace UI

1. Log into BaseSpace: https://basespace.illumina.com/
2. Go to your **Account Settings** or **Profile Settings**
3. Look for **"API Keys"** or **"Developer"** section
4. Click **"Create API Key"** or **"Generate New Key"**
5. Give it a descriptive name (e.g., "GCS Transfer Pipeline")
6. **Copy the key immediately** - it won't be shown again!

### Step 2: Store in Google Secret Manager

```bash
export PROJECT_ID="asu-ap-gap-data-opstest-18c2"
export SECRET_NAME="basespace-api-key"

# Create the secret
echo -n "YOUR_API_KEY_HERE" | gcloud secrets create $SECRET_NAME \
  --project=$PROJECT_ID \
  --replication-policy="automatic" \
  --data-file=-

# Grant access to service account
gcloud secrets add-iam-policy-binding $SECRET_NAME \
  --project=$PROJECT_ID \
  --member="serviceAccount:YOUR_SERVICE_ACCOUNT@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

### Step 3: Update Workflow to Use API Key

The workflow modification is very similar, just use `BASESPACE_API_KEY` instead:

```nextflow
process TRANSFER_BS_TO_GCS {
    container 'us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs/client:latest'
    
    input:
    tuple val(bs_file_id), val(gcs_output_uri)

    output:
    val gcs_output_uri, emit: gcs_path

    script:
    """
    # Retrieve API key from Secret Manager
    echo "Retrieving BaseSpace API key from Secret Manager..."
    BASESPACE_API_KEY=\$(gcloud secrets versions access latest \
        --secret="basespace-api-key" \
        --project="asu-ap-gap-data-opstest-18c2")
    
    if [ -z "\$BASESPACE_API_KEY" ]; then
        echo "Error: Failed to retrieve BaseSpace API key from Secret Manager"
        exit 1
    fi
    
    # Export API key (BaseSpace CLI will use it automatically)
    export BASESPACE_API_KEY="\$BASESPACE_API_KEY"
    
    # Verify authentication (optional)
    echo "Verifying BaseSpace authentication..."
    bs auth whoami || {
        echo "Error: BaseSpace authentication failed"
        exit 1
    }
    
    # Download the file from BaseSpace
    echo "Downloading file $bs_file_id from BaseSpace..."
    local_filename=\$(bs file get -i $bs_file_id --template '{{.Name}}')
    
    if [ -z "\$local_filename" ]; then
        echo "Error: Failed to get file metadata for $bs_file_id"
        exit 1
    fi
    
    # Download the file
    bs download file -i $bs_file_id --output ./
    
    if [ ! -f "\$local_filename" ]; then
        echo "Error: BaseSpace file download failed for $bs_file_id."
        exit 1
    fi
    
    # Upload to GCS
    echo "Uploading \$local_filename to $gcs_output_uri..."
    gsutil cp "\$local_filename" "$gcs_output_uri"
    
    if [ \$? -ne 0 ]; then
        echo "Error: GCS upload failed for $gcs_output_uri."
        exit 1
    fi
    
    echo "Transfer complete for $bs_file_id to $gcs_output_uri."
    
    # Clean up (security best practice)
    unset BASESPACE_API_KEY
    """
}
```

## Alternative: Configure in Seqera Platform

Even simpler - configure the API key as an environment variable in Seqera:

1. In Seqera Platform → Compute Environment settings
2. Add environment variable:
   - **Name**: `BASESPACE_API_KEY`
   - **Value**: Retrieve from Secret Manager (Seqera supports this)
3. The workflow just needs to verify it's set:

```nextflow
script:
"""
if [ -z "\$BASESPACE_API_KEY" ]; then
    echo "Error: BASESPACE_API_KEY not set"
    exit 1
fi

# Rest of script - API key is already available
bs file get -i $bs_file_id --template '{{.Name}}'
# ... etc
"""
```

## Security Considerations

Even though API keys are long-lived, you can still secure them:

1. ✅ **Store in Secret Manager** - Never hardcode
2. ✅ **Rotate periodically** - Update the secret every 6-12 months
3. ✅ **Use least privilege** - Only grant necessary permissions
4. ✅ **Monitor usage** - Check BaseSpace logs for unusual activity
5. ✅ **Revoke if compromised** - Can be revoked immediately in BaseSpace UI

## Summary

**Use API Key because:**
- Your workflow is fully automated
- No user interaction required
- Simpler implementation
- No token expiration to worry about
- Better suited for containerized, scheduled jobs

The only code difference is using `BASESPACE_API_KEY` instead of `BASESPACE_ACCESS_TOKEN` - everything else stays the same!

