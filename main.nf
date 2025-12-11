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
    container 'us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs/client:latest'
    
    input:
    tuple val(bs_file_id), val(gcs_output_uri)

    output:
    val gcs_output_uri, emit: gcs_path

    script:
    """
    # Retrieve BaseSpace API key from Google Secret Manager
    echo "Retrieving BaseSpace API key from Secret Manager..."
    BASESPACE_API_KEY=\$(gcloud secrets versions access latest \
        --secret="${params.basespace_secret_name}" \
        --project="${params.gcp_project}" 2>&1)
    
    # Check if secret retrieval was successful
    if [ \$? -ne 0 ] || [ -z "\$BASESPACE_API_KEY" ]; then
        echo "Error: Failed to retrieve BaseSpace API key from Secret Manager"
        echo "Secret name: ${params.basespace_secret_name}"
        echo "Project: ${params.gcp_project}"
        echo "Error output: \$BASESPACE_API_KEY"
        exit 1
    fi
    
    # Export API key as environment variable (BaseSpace CLI will use it automatically)
    export BASESPACE_API_KEY="\$BASESPACE_API_KEY"
    
    # Verify BaseSpace authentication (optional but recommended)
    echo "Verifying BaseSpace authentication..."
    if ! bs auth whoami > /dev/null 2>&1; then
        echo "Error: BaseSpace authentication failed"
        echo "Please verify the API key is valid and has necessary permissions"
        exit 1
    fi
    
    # Download the file from BaseSpace using the BaseSpace CLI
    echo "Downloading file $bs_file_id from BaseSpace..."
    
    # Get the file name from the BaseSpace metadata
    local_filename=\$(bs file get -i $bs_file_id --template '{{.Name}}')
    
    if [ -z "\$local_filename" ]; then
        echo "Error: Failed to get file metadata for BaseSpace file ID: $bs_file_id"
        echo "The file may not exist or you may not have access to it"
        exit 1
    fi
    
    echo "File name: \$local_filename"
    
    # Download the file from BaseSpace
    if ! bs download file -i $bs_file_id --output ./; then
        echo "Error: BaseSpace file download failed for $bs_file_id"
        exit 1
    fi
    
    # Verify file was downloaded
    if [ ! -f "\$local_filename" ]; then
        echo "Error: Downloaded file not found: \$local_filename"
        exit 1
    fi
    
    echo "Successfully downloaded \$local_filename (\$(du -h "\$local_filename" | cut -f1))"
    
    # Upload the file to Google Cloud Storage
    echo "Uploading \$local_filename to $gcs_output_uri..."
    
    # Use gsutil (part of gcloud) to perform the copy
    if ! gsutil cp "\$local_filename" "$gcs_output_uri"; then
        echo "Error: GCS upload failed for $gcs_output_uri"
        exit 1
    fi
    
    echo "Successfully uploaded to $gcs_output_uri"
    echo "Transfer complete for $bs_file_id to $gcs_output_uri"
    
    # Clean up API key from environment (security best practice)
    unset BASESPACE_API_KEY
    """
}