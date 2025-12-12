FROM gcr.io/google.com/cloudsdktool/google-cloud-cli:stable

# Set environment to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Ensure we're running as root
USER root

# Update package lists with retry logic
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get update -y

# Install only packages that might be missing
# curl, python3, and ca-certificates are likely already in the base image
RUN apt-get install -y --no-install-recommends \
        wget \
        unzip \
        procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install the BaseSpace CLI (`bs`)
ENV BASESPACE_CLI_VERSION=latest

# Download, rename, and set permissions for the BaseSpace CLI
RUN wget "https://launch.basespace.illumina.com/CLI/${BASESPACE_CLI_VERSION}/amd64-linux/bs" \
    -O /usr/local/bin/bs && \
    chmod +x /usr/local/bin/bs

# 3. Verification
# Ensure both CLIs are available for the Nextflow process
RUN bs --version
RUN gcloud --version
RUN gsutil version
RUN ps --version

# Set the entrypoint or default command if needed, but for Nextflow, 
# the `nextflow.config` process command will override the entrypoint.