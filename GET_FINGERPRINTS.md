# How to Get SHA-1 and SHA-256 Fingerprints

## For Production (Release Build) - Already Done ✅

**Keystore Location:** `android/upload-keystore.jks`

**Command:**
```bash
cd android
/Applications/Android\ Studio.app/Contents/jbr/Contents/Home/bin/keytool -list -v -keystore upload-keystore.jks -alias upload -storepass ahadi2024 -keypass ahadi2024
```

**Your Production Fingerprints:**
- **SHA-1:** `28:76:F5:61:BF:BB:50:41:41:E1:E8:F5:49:28:A0:73:BF:0A:46:E9`
- **SHA-256:** `32:D8:02:82:47:51:84:D5:8D:90:8A:C1:08:FB:4E:E4:C2:42:CB:97:A8:10:DE:A9:FF:3E:A4:8E:49:24:FF:0E`

---

## For Debug/Testing (Optional)

**Keystore Location:** `~/.android/debug.keystore` (default Android debug keystore)

**Command:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**To extract just SHA-1:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1
```

**To extract just SHA-256:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA256
```

---

## Quick Reference

### Production Keystore (for Play Store)
```bash
# Full path to your release keystore
keystore: android/upload-keystore.jks
alias: upload
storepass: ahadi2024
keypass: ahadi2024
```

### Debug Keystore (for testing)
```bash
# Default Android debug keystore
keystore: ~/.android/debug.keystore
alias: androiddebugkey
storepass: android
keypass: android
```

---

## What You Need to Do

**For Production (REQUIRED):**
1. Add the **production SHA-1** and **SHA-256** fingerprints to Firebase Console
2. These are the ones we already extracted above
3. This is what you need for Play Store releases

**For Debug (OPTIONAL - only if you want to test Google Sign-In in debug mode):**
1. Run the debug keystore command above
2. Add those fingerprints to Firebase Console as well
3. This allows Google Sign-In to work during development/testing

---

## Important Notes

- **Production fingerprints** are REQUIRED for Play Store releases
- **Debug fingerprints** are optional - only needed if you want to test Google Sign-In during development
- You can add multiple fingerprints to Firebase Console (both debug and release)
- The app will work with whichever fingerprint matches the keystore used to sign it
