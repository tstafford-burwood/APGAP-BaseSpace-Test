# Troubleshooting Docker Build Error: apt-get exit code 100

## The Problem

The error `exit code: 100` from `apt-get` typically indicates:
- Package repository connectivity issues
- Corrupted package lists
- Base image compatibility issues
- Network/proxy issues during build

## Solution 1: Updated Dockerfile (Already Applied)

The Dockerfile has been updated to:
- Remove inline comments from RUN commands
- Add `DEBIAN_FRONTEND=noninteractive` to avoid interactive prompts
- Fix indentation and command structure

## Solution 2: Try Building Again

The updated Dockerfile should work. Try building again:

```bash
docker build . --platform linux/amd64 \
  -t us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client:latest
```

## Solution 3: If Still Failing - Debug the Base Image

If it still fails, test if the base image works:

```bash
# Test the base image
docker run --rm gcr.io/google.com/cloudsdktool/google-cloud-cli:stable \
  sh -c "apt-get update && apt-get install -y wget"
```

## Solution 4: Alternative - Use Different Base Image

If the Google Cloud SDK image has issues, we can use a Debian base and install gcloud:

```dockerfile
FROM debian:bullseye-slim

# Install Google Cloud SDK and dependencies
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        gnupg \
        wget \
        unzip \
        python3 \
        procps && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
    apt-get update -y && \
    apt-get install -y google-cloud-cli && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Rest of Dockerfile...
```

## Solution 5: Network/Proxy Issues

If you're behind a proxy or have network issues:

```bash
# Build with network debugging
docker build . --platform linux/amd64 \
  --network=host \
  -t us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client:latest
```

## Solution 6: Clear Docker Build Cache

Sometimes cached layers cause issues:

```bash
# Build without cache
docker build . --platform linux/amd64 \
  --no-cache \
  -t us-central1-docker.pkg.dev/asu-ap-gap-data-opstest-18c2/bs-gcs2/client:latest
```

## Most Likely Fix

The updated Dockerfile (Solution 1) should resolve the issue. The problem was likely:
1. Inline comment in the middle of the RUN command
2. Missing `DEBIAN_FRONTEND=noninteractive`

Try building again with the updated Dockerfile!

