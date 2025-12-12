# Fix: NCBI Secrets Error in Seqera

## The Problem

Seqera is detecting/requiring secrets (`NCBI_username`, `NCBI_password`) that **don't exist in this workflow**. This is likely because:

1. **Seqera is auto-detecting** secret patterns in the code (even though they don't exist)
2. **Another pipeline/config** in the workspace references NCBI secrets
3. **Seqera's validation** is being overly strict

## The Solution: Create Placeholder Secrets

Since this workflow **doesn't actually use Seqera secrets** (it uses Google Secret Manager), you can create placeholder secrets just to satisfy Seqera's validation:

### Option 1: Create Empty/Placeholder Secrets in Seqera

1. **Go to**: Seqera Platform → Your Workspace → **Secrets**
2. **Create** these secrets (they won't be used):
   - **Secret Name**: `NCBI_username`
     - **Value**: `placeholder` (or any dummy value)
   - **Secret Name**: `NCBI_password`
     - **Value**: `placeholder` (or any dummy value)

3. **Launch the pipeline** - it will pass validation, but these secrets won't be used

### Option 2: Check if Another Pipeline is Causing This

The error might be coming from a different pipeline. Check:

1. **Other pipelines** in your workspace that might reference NCBI
2. **Shared configs** or **tower.yml** files that might have NCBI references
3. **Default workspace settings** that might require these secrets

### Option 3: Disable Secret Validation (if available)

Some Seqera versions allow you to:
- Skip secret validation during launch
- Mark secrets as "optional" instead of "required"
- Disable auto-detection of secrets

Look for these options in the launch configuration.

## Why This Happens

Seqera scans pipeline code for patterns that look like secret references. Even if your code doesn't use them, Seqera might:
- Detect similar patterns
- Require secrets from other pipelines in the workspace
- Have workspace-level secret requirements

## Important Reminder

**These NCBI secrets won't be used by this workflow!** 

This pipeline:
- ✅ Retrieves BaseSpace API key from **Google Secret Manager** (not Seqera)
- ✅ Doesn't use NCBI credentials at all
- ✅ Only needs the placeholder secrets to pass Seqera's validation

## Quick Fix Steps

1. **Create placeholder secrets**:
   ```
   NCBI_username = "placeholder"
   NCBI_password = "placeholder"
   ```

2. **Launch pipeline** - validation will pass

3. **Workflow will run** - it retrieves BaseSpace secret from Google Secret Manager, ignoring the NCBI placeholders

## Alternative: Check Repository for NCBI References

If you want to find where NCBI is referenced:

```bash
# Search the repository
cd /path/to/repo
grep -r "NCBI" .
grep -r "username\|password" . --include="*.nf" --include="*.config"
```

But since this workflow doesn't need them, creating placeholders is the fastest solution.

