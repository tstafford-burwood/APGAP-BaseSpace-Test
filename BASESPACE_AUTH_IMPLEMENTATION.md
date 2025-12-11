# BaseSpace Authentication with Google Secret Manager

## Overview

The BaseSpace CLI (`bs`) requires authentication via an access token to download files. This document explains how to integrate Google Secret Manager to securely retrieve and use the BaseSpace access token in your Nextflow workflow.

## How BaseSpace CLI Authentication Works

### Authentication Methods

1. **Access Token (Recommended for automation)**
   - Set via environment variable: `BASESPACE_ACCESS_TOKEN`
   - Pass via command flag: `bs --access-token TOKEN command`
   - The token is a long-lived OAuth token that grants access to BaseSpace resources

2. **Config File (Interactive use)**
   - Stored in `~/.basespace/default.cfg` after running `bs auth login`
   - Not suitable for containerized workflows

### Current Problem

Your workflow runs `bs` commands without authentication:
```bash
bs file get -i $bs_file_id --template '{{.Name}}'
bs download file -i $bs_file_id --output ./
```

These will fail with authentication errors unless the token is provided.

## Implementation: Using Google Secret Manager

### Architecture

```
┌─────────────────┐
│  Secret Manager │  Stores: basespace-access-token
└────────┬────────┘
         │
         │ Retrieved at runtime
         ▼
┌─────────────────┐
│  Nextflow       │  Process retrieves secret
│  Process        │  Sets BASESPACE_ACCESS_TOKEN
└────────┬────────┘
         │
         │ Authenticated requests
         ▼
┌─────────────────┐
│  BaseSpace API  │  Downloads files
└─────────────────┘
```

### Step-by-Step Implementation

#### 1. Store Token in Secret Manager

```bash
# Set your GCP project
export PROJECT_ID="asu-ap-gap-data-opstest-18c2"
export SECRET_NAME="basespace-access-token"

# Create secret (first time only)
echo -n "YOUR_BASESPACE_TOKEN_HERE" | gcloud secrets create $SECRET_NAME \
  --project=$PROJECT_ID \
  --replication-policy="automatic" \
  --data-file=-

# Or update existing secret
echo -n "YOUR_BASESPACE_TOKEN_HERE" | gcloud secrets versions add $SECRET_NAME \
  --project=$PROJECT_ID \
  --data-file=-
```

#### 2. Grant Access to Service Account

The compute environment's service account needs permission to access the secret:

```bash
# Get your service account email (from Seqera compute environment settings)
export SERVICE_ACCOUNT="your-service-account@${PROJECT_ID}.iam.gserviceaccount.com"

# Grant secret accessor role
gcloud secrets add-iam-policy-binding $SECRET_NAME \
  --project=$PROJECT_ID \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/secretmanager.secretAccessor"
```

#### 3. Modified Workflow Implementation

Here's how to modify `main.nf` to retrieve and use the secret:

```nextflow
// main.nf
nextflow.enable.dsl=2

// Parameters
params.basespace_secret_name = 'basespace-access-token'
params.gcp_project = 'asu-ap-gap-data-opstest-18c2'

workflow {
    Channel
        .of(
            [ '42274677162', 'gs://a-test-output/2025WW01450_S8_L001_R1_001.fastq.gz' ],
            [ '42274677163', 'gs://a-test-output/2025WW01450_S8_L001_R2_001.fastq.gz' ]
        )
        .set { bs_files_ch }

    TRANSFER_BS_TO_GCS(bs_files_ch)
}

process TRANSFER_BS_TO_GCS {
    container 'us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs/client:latest'
    
    input:
    tuple val(bs_file_id), val(gcs_output_uri)

    output:
    val gcs_output_uri, emit: gcs_path

    script:
    """
    # Retrieve BaseSpace access token from Secret Manager
    echo "Retrieving BaseSpace access token from Secret Manager..."
    BASESPACE_TOKEN=\$(gcloud secrets versions access latest \
        --secret="${params.basespace_secret_name}" \
        --project="${params.gcp_project}")
    
    if [ -z "\$BASESPACE_TOKEN" ]; then
        echo "Error: Failed to retrieve BaseSpace access token from Secret Manager"
        exit 1
    fi
    
    # Export token as environment variable (BaseSpace CLI will use it automatically)
    export BASESPACE_ACCESS_TOKEN="\$BASESPACE_TOKEN"
    
    # Verify authentication (optional check)
    echo "Verifying BaseSpace authentication..."
    bs auth whoami || {
        echo "Error: BaseSpace authentication failed"
        exit 1
    }
    
    # Download the file from BaseSpace
    echo "Downloading file $bs_file_id from BaseSpace..."
    
    # Get the file name from the BaseSpace metadata
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
    
    # Upload the file to Google Cloud Storage
    echo "Uploading \$local_filename to $gcs_output_uri..."
    gsutil cp "\$local_filename" "$gcs_output_uri"
    
    if [ \$? -ne 0 ]; then
        echo "Error: GCS upload failed for $gcs_output_uri."
        exit 1
    fi
    
    echo "Transfer complete for $bs_file_id to $gcs_output_uri."
    
    # Clean up token from environment (security best practice)
    unset BASESPACE_ACCESS_TOKEN
    """
}
```

### Alternative: Using Environment Variable from Seqera

Instead of retrieving in the script, you can configure the secret as an environment variable in Seqera Platform:

#### In Seqera Platform:
1. Go to your Compute Environment settings
2. Add environment variable:
   - Name: `BASESPACE_ACCESS_TOKEN`
   - Value: Retrieve from Secret Manager (Seqera supports this natively)

#### Simplified Workflow:

```nextflow
process TRANSFER_BS_TO_GCS {
    container 'us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs/client:latest'
    
    // Token is automatically available via environment variable
    // No need to retrieve in script if configured in Seqera
    
    input:
    tuple val(bs_file_id), val(gcs_output_uri)

    output:
    val gcs_output_uri, emit: gcs_path

    script:
    """
    # Verify token is available
    if [ -z "\$BASESPACE_ACCESS_TOKEN" ]; then
        echo "Error: BASESPACE_ACCESS_TOKEN not set"
        exit 1
    fi
    
    # Rest of the script remains the same...
    echo "Downloading file $bs_file_id from BaseSpace..."
    local_filename=\$(bs file get -i $bs_file_id --template '{{.Name}}')
    bs download file -i $bs_file_id --output ./
    
    if [ ! -f "\$local_filename" ]; then
        echo "Error: BaseSpace file download failed for $bs_file_id."
        exit 1
    fi
    
    echo "Uploading \$local_filename to $gcs_output_uri..."
    gsutil cp "\$local_filename" "$gcs_output_uri"
    
    if [ \$? -ne 0 ]; then
        echo "Error: GCS upload failed for $gcs_output_uri."
        exit 1
    fi
    
    echo "Transfer complete for $bs_file_id to $gcs_output_uri."
    """
}
```

## Security Best Practices

1. **Never commit tokens to git** - Always use Secret Manager
2. **Rotate tokens regularly** - Update the secret in Secret Manager
3. **Use least privilege** - Only grant secret access to necessary service accounts
4. **Clean up in scripts** - Unset environment variables after use
5. **Use secret versions** - Secret Manager tracks versions for audit trails

## Testing Locally

To test the authentication locally:

```bash
# Set token manually
export BASESPACE_ACCESS_TOKEN="your-token-here"

# Test BaseSpace CLI
bs auth whoami
bs file get -i 42274677162 --template '{{.Name}}'
```

## Troubleshooting

### Error: "Permission denied" when accessing secret
- Verify service account has `roles/secretmanager.secretAccessor` role
- Check the service account email matches your compute environment

### Error: "Authentication failed" from BaseSpace
- Verify token is valid: `bs auth whoami`
- Check token hasn't expired
- Ensure token has necessary scopes/permissions

### Error: "Secret not found"
- Verify secret name matches exactly
- Check project ID is correct
- Ensure secret exists: `gcloud secrets list --project=$PROJECT_ID`

## Next Steps

1. Create the secret in Secret Manager
2. Grant access to your service account
3. Choose implementation method (retrieve in script vs. Seqera env var)
4. Update the workflow accordingly
5. Test with a small file first

