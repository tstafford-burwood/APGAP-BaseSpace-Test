// main.nf
nextflow.enable.dsl=2

// Parameters for Secret Manager configuration
params.basespace_secret_name = 'basespace-api-key'
params.gcp_project = 'asu-ap-gap-data-opstest-18c2'

/*
 * This channel will hold the BaseSpace file ID and the desired output file name.
 * In a real pipeline, this channel would be populated by a previous process
 * that queries the BaseSpace API.
 * Format: [basespace_file_id, gcs_output_path]
 */
workflow {
    Channel
        .of(
            [ '42274677162', 'gs://a-test-output/2025WW01450_S8_L001_R1_001.fastq.gz' ],
            [ '42274677163', 'gs://a-test-output/2025WW01450_S8_L001_R2_001.fastq.gz' ]
        )
        .set { bs_files_ch }

    // Execute the transfer process for each file
    TRANSFER_BS_TO_GCS(bs_files_ch)
}

process TRANSFER_BS_TO_GCS {
    // Docker container with BaseSpace CLI and Google Cloud SDK
    container 'us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client:latest'
    
    input:
    tuple val(bs_file_id), val(gcs_output_uri)

    output:
    val gcs_output_uri, emit: gcs_path

    script:
    """
    set -x  # Print commands as they execute (for debugging)
    
    echo "=========================================="
    echo "Starting BaseSpace to GCS Transfer Process"
    echo "=========================================="
    echo "Timestamp: \$(date)"
    echo "Working directory: \$(pwd)"
    echo "User: \$(whoami)"
    echo ""
    
    # Log environment information
    echo "=== Environment Information ==="
    echo "PATH: \$PATH"
    echo "HOME: \$HOME"
    echo "PWD: \$(pwd)"
    echo ""
    
    # Check required tools are available
    echo "=== Checking Required Tools ==="
    if ! command -v gcloud &> /dev/null; then
        echo "ERROR: gcloud command not found!"
        echo "PATH: \$PATH"
        exit 1
    fi
    echo "✓ gcloud found: \$(gcloud --version | head -n1)"
    
    if ! command -v bs &> /dev/null; then
        echo "ERROR: bs (BaseSpace CLI) command not found!"
        exit 1
    fi
    echo "✓ bs found: \$(bs --version 2>&1 | head -n1)"
    
    if ! command -v gsutil &> /dev/null; then
        echo "ERROR: gsutil command not found!"
        exit 1
    fi
    echo "✓ gsutil found: \$(gsutil version 2>&1 | head -n1)"
    echo ""
    
    # Check GCP authentication
    echo "=== Checking GCP Authentication ==="
    echo "Configuring gcloud to use Application Default Credentials..."
    
    # In compute environments, use Application Default Credentials (ADC)
    # Set the project explicitly
    gcloud config set project "${params.gcp_project}" 2>&1 || true
    
    # Verify ADC is available
    echo "Testing Application Default Credentials..."
    if ! gcloud auth application-default print-access-token &> /dev/null; then
        echo "WARNING: Application Default Credentials not available"
        echo "Attempting to use service account from metadata server..."
        
        # Try to get service account from metadata server (GCP compute environments)
        SERVICE_ACCOUNT=\$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/email 2>/dev/null || echo "")
        
        if [ -n "\$SERVICE_ACCOUNT" ]; then
            echo "✓ Found service account from metadata: \$SERVICE_ACCOUNT"
            echo "Using service account authentication..."
        else
            echo "ERROR: No GCP authentication available"
            echo "This compute environment may not have a service account configured"
            exit 1
        fi
    else
        echo "✓ Application Default Credentials available"
        # Get the account being used
        ACTIVE_ACCOUNT=\$(gcloud auth application-default print-access-token 2>&1 | head -n1 || echo "ADC")
        echo "Using Application Default Credentials"
    fi
    echo ""
    
    # Retrieve BaseSpace API key from Google Secret Manager
    echo "=== Retrieving BaseSpace API Key from Secret Manager ==="
    echo "Secret name: ${params.basespace_secret_name}"
    echo "Project: ${params.gcp_project}"
    echo ""
    
    # First, test if we can access the secret (without capturing output)
    echo "Testing secret access..."
    if ! gcloud secrets describe "${params.basespace_secret_name}" --project="${params.gcp_project}" &> /dev/null; then
        echo "ERROR: Cannot access secret '${params.basespace_secret_name}'"
        echo ""
        echo "Troubleshooting information:"
        echo "- Project: ${params.gcp_project}"
        echo "- Secret name: ${params.basespace_secret_name}"
        echo ""
        echo "Attempting to list available secrets (to verify permissions)..."
        gcloud secrets list --project="${params.gcp_project}" 2>&1 || {
            echo "Cannot list secrets - this indicates a permission issue"
            echo "Please ensure the compute environment's service account has:"
            echo "  - roles/secretmanager.secretAccessor (for the specific secret)"
            echo "  - roles/secretmanager.viewer (to list secrets)"
        }
        exit 1
    fi
    echo "✓ Secret exists and is accessible"
    echo ""
    
    # Now retrieve the secret value
    echo "Retrieving secret value..."
    SECRET_OUTPUT=\$(gcloud secrets versions access latest \
        --secret="${params.basespace_secret_name}" \
        --project="${params.gcp_project}" 2>&1)
    SECRET_EXIT_CODE=\$?
    
    echo "gcloud command exit code: \$SECRET_EXIT_CODE"
    echo "Secret output length: \${#SECRET_OUTPUT} characters"
    
    if [ \$SECRET_EXIT_CODE -ne 0 ]; then
        echo "ERROR: Failed to retrieve secret (exit code: \$SECRET_EXIT_CODE)"
        echo "Error output:"
        echo "\$SECRET_OUTPUT"
        echo ""
        echo "Debugging information:"
        echo "Current service account (from metadata server):"
        curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/email 2>&1 || echo "Not available via metadata server"
        echo ""
        echo "Project configuration:"
        gcloud config get-value project 2>&1 || echo "No project configured"
        echo ""
        echo "Application Default Credentials status:"
        gcloud auth application-default print-access-token &> /dev/null && echo "ADC is available" || echo "ADC is not available"
        exit 1
    fi
    
    if [ -z "\$SECRET_OUTPUT" ]; then
        echo "ERROR: Secret retrieval returned empty value"
        echo "This could indicate:"
        echo "  - Secret exists but has no value"
        echo "  - Permission issue reading secret value"
        echo "  - Secret version issue"
        exit 1
    fi
    
    # Clean the secret value (remove leading/trailing whitespace and newlines)
    BASESPACE_API_KEY=\$(echo "\$SECRET_OUTPUT" | tr -d '\n\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    echo "✓ Secret retrieved successfully (length: \${#BASESPACE_API_KEY} characters)"
    echo ""
    
    # Validate API key is not empty after cleaning
    if [ -z "\$BASESPACE_API_KEY" ]; then
        echo "ERROR: API key is empty after cleaning"
        echo "Original secret length: \${#SECRET_OUTPUT} characters"
        exit 1
    fi
    
    # Export API key as environment variable (BaseSpace CLI will use it automatically)
    echo "=== Setting BaseSpace API Key ==="
    export BASESPACE_API_KEY="\$BASESPACE_API_KEY"
    # Also set as ACCESS_TOKEN (some CLI versions use this)
    export BASESPACE_ACCESS_TOKEN="\$BASESPACE_API_KEY"
    echo "✓ BASESPACE_API_KEY environment variable set"
    echo "✓ BASESPACE_ACCESS_TOKEN environment variable set (for compatibility)"
    echo "Key length: \${#BASESPACE_API_KEY} characters"
    echo "Key preview (first 10 chars): \${BASESPACE_API_KEY:0:10}..."
    echo ""
    
    # Verify BaseSpace authentication
    echo "=== Verifying BaseSpace Authentication ==="
    echo "Testing BaseSpace API key..."
    
    # Try with environment variable first (most common method)
    WHOAMI_OUTPUT=\$(bs auth whoami 2>&1)
    WHOAMI_EXIT=\$?
    
    # If that doesn't work, try with --access-token flag (if supported)
    if [ \$WHOAMI_EXIT -ne 0 ]; then
        echo "Trying with --access-token flag..."
        WHOAMI_OUTPUT=\$(bs --access-token "\$BASESPACE_API_KEY" auth whoami 2>&1)
        WHOAMI_EXIT=\$?
    fi
    
    if [ \$WHOAMI_EXIT -ne 0 ]; then
        echo "ERROR: BaseSpace authentication failed (exit code: \$WHOAMI_EXIT)"
        echo "Error output:"
        echo "\$WHOAMI_OUTPUT"
        echo ""
        echo "Debugging information:"
        echo "API key is set: \${BASESPACE_API_KEY:+YES}"
        echo "API key length: \${#BASESPACE_API_KEY} characters"
        echo "API key format check (should start with alphanumeric):"
        echo "\${BASESPACE_API_KEY:0:20}..."
        echo ""
        echo "Please verify:"
        echo "  1. The API key in Secret Manager is valid"
        echo "  2. The API key has not expired"
        echo "  3. The API key has necessary permissions"
        exit 1
    fi
    echo "✓ BaseSpace authentication successful"
    echo "User info: \$WHOAMI_OUTPUT"
    echo ""
    
    # Download the file from BaseSpace using the BaseSpace CLI
    echo "=== BaseSpace File Operations ==="
    echo "BaseSpace file ID: $bs_file_id"
    echo "Target GCS path: $gcs_output_uri"
    echo ""
    
    # Get the file name from the BaseSpace metadata
    echo "Retrieving file metadata from BaseSpace..."
    FILE_METADATA_OUTPUT=\$(bs file get -i $bs_file_id --template '{{.Name}}' 2>&1)
    FILE_METADATA_EXIT=\$?
    
    if [ \$FILE_METADATA_EXIT -ne 0 ]; then
        echo "ERROR: Failed to get file metadata (exit code: \$FILE_METADATA_EXIT)"
        echo "Error output:"
        echo "\$FILE_METADATA_OUTPUT"
        echo ""
        echo "The file may not exist or you may not have access to it"
        echo "File ID: $bs_file_id"
        exit 1
    fi
    
    if [ -z "\$FILE_METADATA_OUTPUT" ]; then
        echo "ERROR: File metadata returned empty"
        echo "File ID: $bs_file_id"
        exit 1
    fi
    
    local_filename="\$FILE_METADATA_OUTPUT"
    echo "✓ File metadata retrieved"
    echo "File name: \$local_filename"
    echo ""
    
    # Download the file from BaseSpace
    echo "Downloading file from BaseSpace..."
    echo "File ID: $bs_file_id"
    echo "Output directory: \$(pwd)"
    
    DOWNLOAD_OUTPUT=\$(bs download file -i $bs_file_id --output ./ 2>&1)
    DOWNLOAD_EXIT=\$?
    
    if [ \$DOWNLOAD_EXIT -ne 0 ]; then
        echo "ERROR: BaseSpace file download failed (exit code: \$DOWNLOAD_EXIT)"
        echo "Error output:"
        echo "\$DOWNLOAD_OUTPUT"
        echo ""
        echo "File ID: $bs_file_id"
        echo "Expected filename: \$local_filename"
        exit 1
    fi
    echo "✓ Download command completed"
    echo "Download output: \$DOWNLOAD_OUTPUT"
    echo ""
    
    # Verify file was downloaded
    echo "Verifying downloaded file..."
    if [ ! -f "\$local_filename" ]; then
        echo "ERROR: Downloaded file not found"
        echo "Expected file: \$local_filename"
        echo "Current directory: \$(pwd)"
        echo "Files in current directory:"
        ls -la || true
        echo ""
        echo "Checking for similar filenames..."
        find . -name "*\${local_filename##*.}" -type f 2>/dev/null || true
        exit 1
    fi
    
    FILE_SIZE=\$(du -h "\$local_filename" | cut -f1)
    echo "✓ File downloaded successfully"
    echo "File: \$local_filename"
    echo "Size: \$FILE_SIZE"
    echo ""
    
    # Upload the file to Google Cloud Storage
    echo "=== Google Cloud Storage Upload ==="
    echo "Source file: \$local_filename"
    echo "Destination: $gcs_output_uri"
    echo ""
    
    # Verify GCS authentication
    echo "Verifying GCS access..."
    if ! gsutil ls gs:// &> /dev/null; then
        echo "WARNING: Cannot list GCS buckets, but will attempt upload"
    else
        echo "✓ GCS access verified"
    fi
    echo ""
    
    # Use gsutil (part of gcloud) to perform the copy
    echo "Uploading file to GCS..."
    UPLOAD_OUTPUT=\$(gsutil cp "\$local_filename" "$gcs_output_uri" 2>&1)
    UPLOAD_EXIT=\$?
    
    if [ \$UPLOAD_EXIT -ne 0 ]; then
        echo "ERROR: GCS upload failed (exit code: \$UPLOAD_EXIT)"
        echo "Error output:"
        echo "\$UPLOAD_OUTPUT"
        echo ""
        echo "Source file: \$local_filename"
        echo "Destination: $gcs_output_uri"
        echo "File exists: \$([ -f "\$local_filename" ] && echo 'YES' || echo 'NO')"
        exit 1
    fi
    
    echo "✓ Upload completed successfully"
    echo "Upload output: \$UPLOAD_OUTPUT"
    echo ""
    
    echo "=========================================="
    echo "Transfer Complete!"
    echo "=========================================="
    echo "BaseSpace file ID: $bs_file_id"
    echo "Local file: \$local_filename"
    echo "GCS destination: $gcs_output_uri"
    echo "File size: \$FILE_SIZE"
    echo "Timestamp: \$(date)"
    echo ""
    
    # Clean up API key from environment (security best practice)
    unset BASESPACE_API_KEY
    echo "✓ API key cleared from environment"
    """
}