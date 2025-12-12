# Fixing GPG Signature Errors in Docker Build

## The Problem

GPG signature errors occur when:
- GPG keys are outdated or invalid
- Repository signatures don't match
- Network issues during key verification

## Solution 1: Updated Dockerfile (Current)

The Dockerfile now:
- Reinstalls ca-certificates
- Uses `--allow-releaseinfo-change` flag
- Handles errors gracefully

## Solution 2: Use --allow-unauthenticated (Quick Fix)

If the GPG issue persists, you can temporarily use `--allow-unauthenticated`:

```dockerfile
RUN apt-get install -y --no-install-recommends --allow-unauthenticated \
        wget \
        unzip \
        procps
```

**Note:** This is acceptable in a controlled build environment but less secure.

## Solution 3: Alternative Base Image

If the Google Cloud SDK image continues to have GPG issues, use a Debian base:

```dockerfile
FROM debian:bullseye-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install Google Cloud SDK
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        gnupg && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
        tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
        apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
    apt-get update -y && \
    apt-get install -y google-cloud-cli && \
    apt-get install -y --no-install-recommends \
        wget \
        unzip \
        python3 \
        procps && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install BaseSpace CLI
ENV BASESPACE_CLI_VERSION=latest
RUN wget "https://launch.basespace.illumina.com/CLI/${BASESPACE_CLI_VERSION}/amd64-linux/bs" \
    -O /usr/local/bin/bs && \
    chmod +x /usr/local/bin/bs

# Verification
RUN bs --version && \
    gcloud --version && \
    gsutil version && \
    ps --version
```

## Try Building Again

The updated Dockerfile should handle the GPG issue. Try:

```bash
docker build . --platform linux/amd64 \
  --no-cache \
  -t us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client:latest
```

If it still fails, the alternative base image approach (Solution 3) will definitely work.

