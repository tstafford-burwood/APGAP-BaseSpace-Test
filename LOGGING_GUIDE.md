# Enhanced Logging for Pipeline Debugging

## What Was Added

The workflow now includes comprehensive logging at every step to help diagnose failures. Here's what you'll see in the logs:

### 1. **Environment Information**
- Timestamp
- Working directory
- User information
- PATH and environment variables

### 2. **Tool Availability Checks**
- Verifies `gcloud`, `bs`, and `gsutil` are available
- Shows versions of each tool
- Fails early if tools are missing

### 3. **GCP Authentication Verification**
- Checks for active gcloud authentication
- Falls back to application default credentials
- Shows which account is being used

### 4. **Secret Manager Access**
- Tests if secret exists and is accessible
- Shows IAM permissions if access fails
- Lists available secrets for debugging
- Captures full error output from gcloud command
- Shows exit codes and output lengths

### 5. **BaseSpace Authentication**
- Tests API key validity
- Shows authentication results
- Displays user information on success

### 6. **File Operations**
- Logs each step of BaseSpace file retrieval
- Shows file metadata
- Verifies downloads completed
- Lists files in directory if expected file not found

### 7. **GCS Upload**
- Verifies GCS access before upload
- Captures full upload output
- Shows detailed error messages on failure

## What to Look For in Logs

When the pipeline fails, check the logs for:

### Secret Retrieval Issues
```
=== Retrieving BaseSpace API Key from Secret Manager ===
```
Look for:
- **"ERROR: Cannot access secret"** → Permission issue
- **"gcloud command exit code: X"** → Non-zero means failure
- **"Secret output length: 0"** → Empty secret or permission issue
- IAM policy output showing missing permissions

### Authentication Issues
```
=== Checking GCP Authentication ===
```
Look for:
- **"ERROR: No GCP authentication available"** → Service account not configured
- **"WARNING: No active gcloud authentication"** → Using application default credentials

### BaseSpace Issues
```
=== Verifying BaseSpace Authentication ===
```
Look for:
- **"ERROR: BaseSpace authentication failed"** → Invalid API key
- Exit code and error output from `bs auth whoami`

### File Download Issues
```
=== BaseSpace File Operations ===
```
Look for:
- **"ERROR: Failed to get file metadata"** → File doesn't exist or no access
- **"ERROR: Downloaded file not found"** → Download failed but command succeeded
- List of files in directory to see what was actually downloaded

## Common Issues and Log Patterns

### Issue: Secret Permission Denied
**Log pattern:**
```
ERROR: Cannot access secret 'basespace-api-key'
Checking secret permissions...
```
**Solution**: Grant `roles/secretmanager.secretAccessor` to service account

### Issue: No GCP Authentication
**Log pattern:**
```
ERROR: No GCP authentication available
Available accounts:
```
**Solution**: Ensure compute environment service account is properly configured

### Issue: Invalid API Key
**Log pattern:**
```
ERROR: BaseSpace authentication failed (exit code: X)
Error output: [authentication error]
```
**Solution**: Verify API key in Secret Manager is valid

### Issue: File Not Found
**Log pattern:**
```
ERROR: Failed to get file metadata
The file may not exist or you may not have access to it
```
**Solution**: Verify BaseSpace file ID is correct and API key has access

## Debugging Tips

1. **Check the section headers** - They show which step failed
2. **Look for exit codes** - Non-zero means failure
3. **Read error output** - Full error messages are now captured
4. **Check tool availability** - Early failures show if tools are missing
5. **Verify authentication** - Both GCP and BaseSpace auth are tested

## Next Steps After Failure

1. **Identify the failing section** from the log headers
2. **Check the error message** in that section
3. **Review the debugging information** provided
4. **Fix the underlying issue** (permissions, credentials, etc.)
5. **Re-run the pipeline** with the same detailed logging

The enhanced logging will help pinpoint exactly where and why the pipeline is failing!

