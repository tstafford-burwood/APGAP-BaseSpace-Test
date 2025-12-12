# Testing and Fixing apt-get Error in Dockerfile

## Quick Test: Check Base Image

First, let's test if the base image works:

```bash
docker run --rm gcr.io/google.com/cloudsdktool/google-cloud-cli:stable \
  sh -c "apt-get update && echo 'apt-get works'"
```

If this fails, the base image might have issues.

## Updated Dockerfile (Simplified)

The Dockerfile has been updated to:
- Remove packages that are likely already in the base image (curl, python3, ca-certificates)
- Only install what's needed: wget, unzip, procps
- Clean apt lists before updating
- Ensure running as root

## Alternative: Test Build with Verbose Output

Build with more verbose output to see the exact error:

```bash
docker build . --platform linux/amd64 \
  --progress=plain \
  --no-cache \
  -t us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client:latest 2>&1 | tee build.log
```

This will show exactly where it fails.

## Alternative Dockerfile (If Base Image Has Issues)

If the Google Cloud SDK image continues to have issues, use this alternative:

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

## Debugging Steps

1. **Test base image:**
   ```bash
   docker run --rm -it gcr.io/google.com/cloudsdktool/google-cloud-cli:stable bash
   # Then inside: apt-get update
   ```

2. **Check if packages exist:**
   ```bash
   docker run --rm gcr.io/google.com/cloudsdktool/google-cloud-cli:stable \
     sh -c "which wget curl python3 ps"
   ```

3. **Build with single package:**
   Try installing just one package at a time to isolate the issue.

## Most Likely Solution

The updated Dockerfile should work. It:
- Removes packages likely already installed (curl, python3, ca-certificates)
- Only installs what's needed
- Cleans before updating

Try building again with the updated Dockerfile!

