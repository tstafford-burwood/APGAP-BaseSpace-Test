# Troubleshooting: Workspace Secrets Causing Pipeline Addition Issues

## The Problem

If you're getting a "permission denied" error when adding the pipeline, and you have existing workspace secrets, Seqera might be:
1. Trying to validate existing secrets when adding a new pipeline
2. Attempting to create a new secret automatically
3. Checking permissions on all workspace secrets

## Important: This Pipeline Doesn't Use Seqera Secrets

**This workflow retrieves secrets directly from Google Secret Manager** - it doesn't use Seqera's secret management at all. The workflow script runs this command inside the container:

```bash
gcloud secrets versions access latest --secret="basespace-api-key"
```

Seqera never touches or needs to know about the secret value.

## Solutions

### Option 1: Check if Seqera is Trying to Auto-Create Secrets

When adding a pipeline, Seqera might try to:
- Scan for secret references in the code
- Auto-create secrets it thinks are needed
- Validate existing secrets

**Solution**: Look for a checkbox or option to "Skip secret validation" or "Don't create secrets automatically" when adding the pipeline.

### Option 2: Verify Your Service Account Permissions

The error might be because Seqera is checking if your service account can access secrets. Verify:

```bash
# Check what service account your compute environment uses
# (From Seqera: Compute Environment → Settings → Service Account)

# Then verify it has Secret Manager access
gcloud secrets get-iam-policy basespace-api-key \
  --project=asu-ap-gap-data-opstest-18c2
```

### Option 3: Temporarily Remove/Disable Unrelated Secrets

If Seqera is validating all workspace secrets:
1. **Temporarily** disable or remove unrelated secrets from the workspace
2. Add the pipeline
3. Re-add the unrelated secrets after

**Note**: This is only if Seqera is blocking pipeline addition due to secret validation.

### Option 4: Add Pipeline via CLI Instead

If the UI is having issues, use the Seqera CLI:

```bash
tw pipeline add \
  --workspace "your-workspace" \
  --name "BaseSpace to GCS Transfer" \
  https://github.com/tstafford-burwood/APGAP-BaseSpace-Test.git \
  --branch theo-test
```

This bypasses the UI and any secret validation it might be doing.

### Option 5: Check the Exact Error Message

The error message should tell you:
- **"Permission denied creating secret"** → Seqera is trying to create a secret (skip this)
- **"Permission denied accessing secret X"** → Seqera is validating an existing secret
- **"Permission denied"** (general) → Could be compute environment or service account issue

## What to Check

1. **Error Details**: What exactly does the error say? Is it about:
   - Creating a secret?
   - Accessing a specific secret?
   - General permissions?

2. **Seqera UI**: When adding the pipeline, are you seeing:
   - A "Secrets" section that you can skip?
   - An automatic secret creation prompt?
   - A validation step that's failing?

3. **Workspace Settings**: Check if there's a workspace-level setting for:
   - Secret validation
   - Auto-creation of secrets
   - Permission checking

## Recommended Approach

1. **Try adding via CLI first** (Option 4) - this bypasses UI secret validation
2. **If CLI works**, the issue is with the UI's secret handling
3. **If CLI also fails**, it's likely a service account permission issue

## Quick Test

Try this to see if it's a secret validation issue:

```bash
# Add pipeline via CLI (bypasses UI)
tw pipeline add \
  --workspace "your-workspace" \
  --name "BaseSpace Transfer" \
  https://github.com/tstafford-burwood/APGAP-BaseSpace-Test.git \
  --branch theo-test
```

If this works, the issue is with the UI's secret validation. If it fails with the same error, it's a different permission issue.

## Summary

- **This pipeline doesn't need Seqera secrets** - it uses Google Secret Manager directly
- **Existing workspace secrets shouldn't matter** - but Seqera might be validating them
- **Try CLI method** to bypass UI secret validation
- **Check exact error message** to understand what Seqera is trying to do

