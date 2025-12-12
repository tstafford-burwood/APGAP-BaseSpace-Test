# Pipeline Parameters for Seqera Platform

## JSON Format (for Seqera UI)

Copy and paste this into the "Pipeline Parameters" section in Seqera:

```json
{
  "basespace_secret_name": "basespace-api-key",
  "gcp_project": "asu-ap-gap-data-opstest-18c2",
  "outdir": "./results"
}
```

## YAML Format (Alternative)

If Seqera accepts YAML format:

```yaml
basespace_secret_name: "basespace-api-key"
gcp_project: "asu-ap-gap-data-opstest-18c2"
outdir: "./results"
```

## Parameter Descriptions

| Parameter | Value | Description |
|----------|-------|-------------|
| `basespace_secret_name` | `basespace-api-key` | Name of the secret in Google Secret Manager containing the BaseSpace API key |
| `gcp_project` | `asu-ap-gap-data-opstest-18c2` | GCP project ID where the secret is stored |
| `outdir` | `./results` | Output directory for workflow results (optional, can be overridden) |

## How to Use in Seqera Platform

### Option 1: Pipeline Settings (Default Parameters)
1. Go to your Pipeline → Settings → Parameters
2. Paste the JSON above into the parameters field
3. These will be used as defaults for all launches

### Option 2: Launch Configuration (Per-Run Parameters)
1. When launching the pipeline, go to the "Parameters" section
2. Paste the JSON or enter parameters individually
3. Override any values as needed for that specific run

### Option 3: Parameters File (CLI)
If using Seqera CLI (`tw`), save the JSON to a file and reference it:
```bash
tw launch \
  --params-file pipeline-params.json \
  https://github.com/tstafford-burwood/APGAP-BaseSpace-Test.git \
  --branch theo-test
```

## Customization

To customize for your environment:

1. **Change secret name**: If your secret has a different name
   ```json
   "basespace_secret_name": "your-secret-name"
   ```

2. **Change project**: If using a different GCP project
   ```json
   "gcp_project": "your-project-id"
   ```

3. **Change output directory**: To use a GCS bucket path
   ```json
   "outdir": "gs://your-bucket/results"
   ```

## Minimal Configuration

If you want to use only the required parameters (secret name and project):

```json
{
  "basespace_secret_name": "basespace-api-key",
  "gcp_project": "asu-ap-gap-data-opstest-18c2"
}
```

The `outdir` parameter is optional and defaults to `./results` if not specified.

