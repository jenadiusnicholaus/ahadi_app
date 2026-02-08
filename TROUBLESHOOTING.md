# Google Sign-In Troubleshooting Guide

## Current Status ✅
- ✅ SHA-1 fingerprint matches: `2876f561bfbb504141e1e8f54928a073bf0a46e9`
- ✅ google-services.json has OAuth client configured
- ✅ Package name matches: `com.quantumvisiontech.ahadi`

## Common Issues & Solutions

### 1. **Did you rebuild after updating google-services.json?**
   - The old bundle was built with empty OAuth client
   - **Solution:** Rebuild with the new google-services.json:
     ```bash
     flutter clean
     flutter build appbundle --release
     ```

### 2. **Are you testing with a RELEASE build?**
   - Debug builds use a different keystore
   - **Solution:** Test with release build:
     ```bash
     flutter build apk --release
     flutter install --release
     ```
   - Or install the release bundle from Play Store Internal Testing

### 3. **What error are you seeing?**
   Check the debug logs for these common errors:

   **"10: Error getting access token"**
   - SHA-1 fingerprint mismatch
   - **Fix:** Verify fingerprint in Firebase Console matches exactly

   **"DEVELOPER_ERROR"**
   - OAuth client not configured
   - **Fix:** Check google-services.json has oauth_client array with your certificate_hash

   **"Sign in failed" or "Network error"**
   - Could be backend issue or network
   - **Fix:** Check backend logs, verify API endpoint is accessible

   **No error, but sign-in doesn't complete**
   - ID token might be null
   - **Fix:** Check debug logs for "ID Token: null"

### 4. **Wait time after adding fingerprints**
   - Changes can take 5-10 minutes to propagate
   - **Solution:** Wait 10 minutes, then rebuild

### 5. **Check Debug Logs**
   Enable debug logging to see what's happening:
   ```dart
   // The code already has debug prints
   // Look for logs starting with 🔐
   ```

   Run with:
   ```bash
   flutter run --release
   # Then check console output for 🔐 logs
   ```

### 6. **Verify google-services.json is included**
   Check that the file is actually in the bundle:
   ```bash
   # Extract and check
   unzip -l build/app/outputs/bundle/release/app-release.aab | grep google-services
   ```

### 7. **Check Google Sign-In Configuration**
   The code uses:
   - Android: `AppConfig.googleClientId` (from .env)
   - iOS: `AppConfig.googleIosClientId` (from .env)
   
   For Android, if `googleClientId` is set, it will use that.
   Otherwise, it uses the OAuth client from google-services.json.

### 8. **Verify OAuth Consent Screen**
   - Go to: https://console.cloud.google.com/apis/credentials/consent
   - Make sure OAuth consent screen is configured
   - Publishing status should be "Testing" or "In production"

## Step-by-Step Debug Checklist

- [ ] Updated google-services.json with OAuth client
- [ ] Waited 10 minutes after adding fingerprints
- [ ] Ran `flutter clean`
- [ ] Rebuilt release bundle: `flutter build appbundle --release`
- [ ] Testing with release build (not debug)
- [ ] Checked debug logs for error messages
- [ ] Verified certificate_hash matches SHA-1 fingerprint
- [ ] Verified package name matches exactly
- [ ] OAuth consent screen is configured

## Quick Test Commands

```bash
# 1. Clean and rebuild
flutter clean
flutter pub get
flutter build apk --release

# 2. Install release APK
flutter install --release

# 3. Check logs while testing
adb logcat | grep -i "google\|signin\|oauth"
```

## Still Not Working?

Please provide:
1. **Exact error message** from the app or logs
2. **Build type** (debug or release)
3. **Debug logs** (look for 🔐 emoji logs)
4. **When did you rebuild?** (before or after updating google-services.json)
