# Google Sign-In Production Setup Guide

## Issue
Google Sign-In fails in production because:
1. Missing SHA-1 fingerprint for release keystore in Google Cloud Console
2. Missing SHA-256 fingerprint (required for Play Store)
3. OAuth client not properly configured for Android production

## Your Release Keystore Fingerprints

**SHA-1:** `28:76:F5:61:BF:BB:50:41:41:E1:E8:F5:49:28:A0:73:BF:0A:46:E9`

**SHA-256:** `32:D8:02:82:47:51:84:D5:8D:90:8A:C1:08:FB:4E:E4:C2:42:CB:97:A8:10:DE:A9:FF:3E:A4:8E:49:24:FF:0E`

**Package Name:** `com.quantumvisiontech.ahadi`

## Method 1: Firebase Console (EASIEST - Recommended)

### Step 1: Go to Firebase Console
1. Visit: https://console.firebase.google.com/
2. Select your project: **ahadi-af7dc**

### Step 2: Navigate to Project Settings
1. Click the **gear icon** (⚙️) next to "Project Overview" at the top left
2. Select **"Project settings"**

### Step 3: Add SHA Fingerprints
1. Scroll down to the **"Your apps"** section
2. Find your Android app: `com.quantumvisiontech.ahadi`
3. Click on the app to expand it
4. You'll see a section called **"SHA certificate fingerprints"**
5. Click **"Add fingerprint"** button
6. Add **SHA-1**: `28:76:F5:61:BF:BB:50:41:41:E1:E8:F5:49:28:A0:73:BF:0A:46:E9`
7. Click **"Add fingerprint"** again
8. Add **SHA-256**: `32:D8:02:82:47:51:84:D5:8D:90:8A:C1:08:FB:4E:E4:C2:42:CB:97:A8:10:DE:A9:FF:3E:A4:8E:49:24:FF:0E`
9. Click **"Save"**

### Step 4: Download Updated google-services.json
1. After adding fingerprints, click **"Download google-services.json"** button
2. Replace your current `android/app/google-services.json` with the new file
3. This will automatically create/update the OAuth client with your fingerprints

---

## Method 2: Google Cloud Console (Alternative)

### Step 1: Go to Google Cloud Console
1. Visit: https://console.cloud.google.com/apis/credentials
2. Make sure you're in project: **ahadi-af7dc** (check top dropdown)

### Step 2: Find or Create OAuth Client
**Option A: If OAuth client exists:**
1. Look for an OAuth 2.0 Client ID with type "Android"
2. If you see: `420635386839-793qmljq70s44a8pbpguigj600pgal2b.apps.googleusercontent.com`, click on it
3. If no Android client exists, go to **Option B**

**Option B: Create new Android OAuth client:**
1. Click **"+ CREATE CREDENTIALS"** at the top
2. Select **"OAuth client ID"**
3. If prompted, configure OAuth consent screen first (fill basic info)
4. Select **"Android"** as application type
5. Enter name: **"Ahadi Android Production"**
6. Package name: `com.quantumvisiontech.ahadi`

### Step 3: Add SHA Fingerprints
1. In the **"Signing-certificate fingerprint (SHA-1)"** field, paste:
   ```
   28:76:F5:61:BF:BB:50:41:41:E1:E8:F5:49:28:A0:73:BF:0A:46:E9
   ```
2. Look for **"SHA-256 certificate fingerprint"** field (may be below SHA-1), paste:
   ```
   32:D8:02:82:47:51:84:D5:8D:90:8A:C1:08:FB:4E:E4:C2:42:CB:97:A8:10:DE:A9:FF:3E:A4:8E:49:24:FF:0E
   ```
3. Click **"CREATE"** (or **"SAVE"** if editing existing)

### Step 4: Update google-services.json
1. Go back to Firebase Console: https://console.firebase.google.com/
2. Project Settings > Your apps > Download updated `google-services.json`
3. Replace `android/app/google-services.json`

---

## Visual Guide - Firebase Console

```
Firebase Console
├── Project: ahadi-af7dc
├── ⚙️ Settings (gear icon)
│   └── Project settings
│       └── Your apps
│           └── Android app (com.quantumvisiontech.ahadi)
│               └── SHA certificate fingerprints
│                   ├── [Add fingerprint] ← Click here
│                   ├── SHA-1: [paste fingerprint]
│                   └── SHA-256: [paste fingerprint]
```

## Verification Steps

After adding fingerprints:

1. **Wait 5-10 minutes** for changes to propagate
2. **Download new google-services.json** from Firebase Console
3. **Replace** `android/app/google-services.json` with the new file
4. **Rebuild** your app: `flutter build appbundle --release`
5. **Test** Google Sign-In on a production build

## Check if It Worked

After updating `google-services.json`, check that the `oauth_client` array is no longer empty:

```json
"oauth_client": [
  {
    "client_id": "420635386839-xxxxx.apps.googleusercontent.com",
    "client_type": 1,
    "android_info": {
      "package_name": "com.quantumvisiontech.ahadi",
      "certificate_hash": "2876f561bfbb504141e1e8f54928a073bf0a46e9"
    }
  }
]
```

## Debug Fingerprints (Optional)

If you also want to test with debug builds, get debug SHA-1:

```bash
cd android
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1
```

Then add that SHA-1 to Firebase Console as well.

## Common Issues

### "10: Error getting access token"
- SHA-1 fingerprint not added or incorrect
- Package name mismatch
- Wait a few minutes after adding fingerprints
- Make sure you downloaded the updated google-services.json

### "Sign in failed" or "DEVELOPER_ERROR"
- OAuth client not created properly
- google-services.json not updated
- Check that oauth_client array in google-services.json is not empty

### Fingerprints not showing in Firebase
- Make sure you're adding them to the correct Android app
- Check package name matches exactly: `com.quantumvisiontech.ahadi`
- Try refreshing the page

## Quick Test

After setup, test with:
```bash
flutter build appbundle --release
flutter install --release
```

Then try Google Sign-In in the app.
