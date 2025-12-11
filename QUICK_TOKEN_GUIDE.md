# Quick Guide: BaseSpace Access Token Creation

## Fastest Method: OAuth2 via Developer Portal

1. **Go to**: https://basespace.illumina.com/ → Login
2. **Click**: "Apps" tab → "App Developer Portal"
3. **Create App**: "My Apps" → "Create New App"
   - Name: "GCS Transfer" (or any name)
   - Redirect URI: `https://localhost/`
   - Save
4. **Get Credentials**: App page → "Credentials" section
   - Copy Client ID and Client Secret
5. **Generate Token**: Open this URL in browser (replace YOUR_CLIENT_ID):
   ```
   https://basespace.illumina.com/oauth/authorize?client_id=YOUR_CLIENT_ID&response_type=token&redirect_uri=https://localhost/
   ```
6. **Authorize** the app when prompted
7. **Copy Token**: From the redirect URL, copy the `access_token` value
8. **Store Securely**: Save to Google Secret Manager

## Alternative: BaseSpace CLI (Easier)

```bash
# Install CLI (if needed)
# Then authenticate
bs auth login

# Token is now in:
cat ~/.basespace/default.cfg | grep "access-token"
```

