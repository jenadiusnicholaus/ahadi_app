# Rebuild and Publish Instructions

## Why You Need to Rebuild

After adding SHA fingerprints to Firebase Console, you need to:
1. Download the updated `google-services.json` (it will contain the OAuth client configuration)
2. Rebuild your app bundle (so the new `google-services.json` is included)
3. Publish the new version to Play Store

## Step-by-Step Process

### 1. Add Fingerprints to Firebase ✅
- Go to Firebase Console
- Add SHA-1 and SHA-256 fingerprints
- **Save** the changes

### 2. Download Updated google-services.json
- In Firebase Console, go to Project Settings > Your apps
- Click **"Download google-services.json"** button
- This file will now have the OAuth client configuration

### 3. Replace google-services.json in Your Project
```bash
# Replace the file
cp ~/Downloads/google-services.json android/app/google-services.json
```

Or manually replace: `android/app/google-services.json` with the downloaded file

### 4. Verify the Update
Check that `google-services.json` now has OAuth client info:
```bash
cat android/app/google-services.json | grep -A 10 "oauth_client"
```

You should see something like:
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

### 5. Rebuild Release Bundle
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

The new bundle will be at: `build/app/outputs/bundle/release/app-release.aab`

### 6. Publish to Play Store
1. Go to Google Play Console
2. Select your app
3. Go to **Production** (or **Internal testing** / **Closed testing**)
4. Click **"Create new release"**
5. Upload the new `app-release.aab` file
6. Fill in release notes
7. Review and publish

## Important Notes

⚠️ **Wait Time**: After adding fingerprints in Firebase, wait 5-10 minutes before downloading `google-services.json` to ensure changes have propagated.

⚠️ **Version Code**: Make sure to increment your version code in `pubspec.yaml` before rebuilding:
```yaml
version: 1.0.1+2  # Increment both version name and build number
```

⚠️ **Testing**: Consider testing the new build in Internal Testing track first before publishing to Production.

## Quick Checklist

- [ ] Added SHA-1 fingerprint to Firebase Console
- [ ] Added SHA-256 fingerprint to Firebase Console
- [ ] Waited 5-10 minutes
- [ ] Downloaded updated `google-services.json`
- [ ] Replaced `android/app/google-services.json`
- [ ] Verified `oauth_client` array is not empty
- [ ] Updated version in `pubspec.yaml`
- [ ] Rebuilt app bundle: `flutter build appbundle --release`
- [ ] Uploaded new bundle to Play Store
- [ ] Tested Google Sign-In in the new build

## Why This is Necessary

The `google-services.json` file contains the OAuth client configuration that Google Sign-In needs. Without the updated file:
- The app won't know which OAuth client to use
- Google Sign-In will fail with "DEVELOPER_ERROR"
- The `oauth_client` array in `google-services.json` will be empty

After updating and rebuilding:
- The app will have the correct OAuth client configuration
- Google Sign-In will work with your release keystore
- Users can sign in successfully
