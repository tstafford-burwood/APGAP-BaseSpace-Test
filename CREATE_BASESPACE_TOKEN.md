# How to Create a BaseSpace Personal Access Token via Website UI

## Method 1: Using BaseSpace Developer Portal (OAuth2 App Method)

This is the standard method for creating access tokens in BaseSpace. You'll create an app and generate tokens through OAuth2.

### Step-by-Step Instructions

#### Step 1: Log into BaseSpace
1. Navigate to **https://basespace.illumina.com/**
2. Sign in with your Illumina account credentials

#### Step 2: Access the Developer Portal
1. Once logged in, look at the top navigation menu
2. Click on the **"Apps"** tab
3. On the Apps page, click on **"App Developer Portal"** or **"Developer Portal"**
   - This may also be accessible via: **https://developer.basespace.illumina.com/**

#### Step 3: Create a New Application
1. In the Developer Portal, click on **"My Apps"** in the navigation
2. Click the **"Create New App"** or **"New App"** button
3. Fill in the application details:
   - **App Name**: e.g., "BaseSpace to GCS Transfer"
   - **Description**: Brief description of what the app does
   - **Redirect URI**: Enter `https://localhost/` (required for OAuth flow, even if not used)
   - **Scopes/Permissions**: Select the permissions you need:
     - `browse global` - Browse global data
     - `read global` - Read global data
     - `read project` - Read project data
     - `write project` - Write project data (if needed)
4. Click **"Create"** or **"Save"** to create the application

#### Step 4: Get Your Client ID and Client Secret
1. After creating the app, you'll be taken to the app details page
2. Navigate to the **"Credentials"** or **"OAuth"** section
3. You'll see:
   - **Client ID**: Copy this value
   - **Client Secret**: Copy this value (you may need to click "Show" or "Reveal")
   - **Keep these secure!**

#### Step 5: Generate an Access Token
You have two options to get an access token:

**Option A: Using OAuth2 Authorization URL (Browser-based)**
1. Construct the authorization URL:
   ```
   https://basespace.illumina.com/oauth/authorize?client_id=YOUR_CLIENT_ID&response_type=token&redirect_uri=https://localhost/
   ```
   Replace `YOUR_CLIENT_ID` with your actual Client ID
2. Paste this URL into your browser
3. You'll be prompted to authorize the app - click **"Authorize"**
4. After authorization, you'll be redirected to a URL that looks like:
   ```
   https://localhost/#access_token=YOUR_ACCESS_TOKEN&token_type=Bearer&expires_in=3600
   ```
5. Copy the `access_token` value from the URL (everything after `access_token=` and before `&`)
6. This is your personal access token!

**Option B: Using BaseSpace CLI (Easier)**
1. Install BaseSpace CLI if you haven't already
2. Run: `bs auth login`
3. Follow the prompts - it will open a browser for authorization
4. After login, your token is stored in `~/.basespace/default.cfg`
5. Extract it with: `grep "access-token" ~/.basespace/default.cfg`

### Method 2: Check Account Settings (Alternative)

Some platforms have a simpler "Personal Access Tokens" section. If available:

1. Log into BaseSpace: **https://basespace.illumina.com/**
2. Click on your **profile/account icon** (usually top right)
3. Go to **"Settings"** or **"Account Settings"**
4. Look for **"API Tokens"**, **"Access Tokens"**, or **"Developer"** section
5. If available, click **"Generate New Token"**
6. Give it a name and set expiration
7. Copy the token immediately (it won't be shown again)

**Note**: This method may not be available in all BaseSpace accounts. If you don't see this option, use Method 1.

## What to Do With Your Token

Once you have your access token:

1. **Store it securely** in Google Secret Manager (see `BASESPACE_AUTH_IMPLEMENTATION.md`)
2. **Never commit it to git** or share it publicly
3. **Use it in your workflow** by setting `BASESPACE_ACCESS_TOKEN` environment variable

## Token Characteristics

- **Format**: Long alphanumeric string
- **Expiration**: Typically expires after a set time (check the `expires_in` value)
- **Scope**: Limited to the permissions you granted when creating the app
- **Revocation**: You can revoke tokens by deleting the app or regenerating credentials

## Troubleshooting

### "App Developer Portal" not visible
- You may need to request developer access
- Contact Illumina support or check if your account type supports API access

### Token expires quickly
- OAuth tokens often have short expiration times
- You may need to implement token refresh logic
- Or use a long-lived token if available in your account settings

### Can't find the token in the URL
- Make sure you're copying the entire token (it can be very long)
- Check browser console for any errors
- Try the CLI method instead

## Quick Reference: Token Storage

After obtaining your token, store it in Google Secret Manager:

```bash
export PROJECT_ID="asu-ap-gap-data-opstest-18c2"
echo -n "YOUR_ACCESS_TOKEN_HERE" | gcloud secrets create basespace-access-token \
  --project=$PROJECT_ID \
  --replication-policy="automatic" \
  --data-file=-
```

