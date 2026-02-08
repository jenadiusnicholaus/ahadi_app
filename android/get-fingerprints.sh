#!/bin/bash

# Script to get SHA-1 and SHA-256 fingerprints from keystores

echo "=========================================="
echo "Getting Keystore Fingerprints"
echo "=========================================="
echo ""

# Check if Java keytool is available
if [ -f "/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool" ]; then
    KEYTOOL="/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool"
elif command -v keytool &> /dev/null; then
    KEYTOOL="keytool"
else
    echo "❌ Error: keytool not found. Please install Java JDK."
    exit 1
fi

echo "📱 PRODUCTION KEYSTORE (Release Build)"
echo "----------------------------------------"
echo "Keystore: android/upload-keystore.jks"
echo ""

if [ -f "upload-keystore.jks" ]; then
    echo "SHA-1:"
    $KEYTOOL -list -v -keystore upload-keystore.jks -alias upload -storepass ahadi2024 -keypass ahadi2024 2>/dev/null | grep -E "^\s+SHA1:" | sed 's/^[[:space:]]*//'
    
    echo ""
    echo "SHA-256:"
    $KEYTOOL -list -v -keystore upload-keystore.jks -alias upload -storepass ahadi2024 -keypass ahadi2024 2>/dev/null | grep -E "^\s+SHA256:" | sed 's/^[[:space:]]*//'
else
    echo "❌ Production keystore not found at: android/upload-keystore.jks"
fi

echo ""
echo "=========================================="
echo ""

echo "🔧 DEBUG KEYSTORE (Development/Testing)"
echo "----------------------------------------"
echo "Keystore: ~/.android/debug.keystore"
echo ""

DEBUG_KEYSTORE="$HOME/.android/debug.keystore"
if [ -f "$DEBUG_KEYSTORE" ]; then
    echo "SHA-1:"
    $KEYTOOL -list -v -keystore "$DEBUG_KEYSTORE" -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep -E "^\s+SHA1:" | sed 's/^[[:space:]]*//'
    
    echo ""
    echo "SHA-256:"
    $KEYTOOL -list -v -keystore "$DEBUG_KEYSTORE" -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep -E "^\s+SHA256:" | sed 's/^[[:space:]]*//'
else
    echo "⚠️  Debug keystore not found at: $DEBUG_KEYSTORE"
    echo "   This is normal if you haven't built a debug app yet."
    echo "   Android will create it automatically on first debug build."
fi

echo ""
echo "=========================================="
echo ""
echo "📝 Next Steps:"
echo "1. Copy the SHA-1 and SHA-256 fingerprints above"
echo "2. Go to Firebase Console: https://console.firebase.google.com/"
echo "3. Project Settings > Your apps > Android app"
echo "4. Add both fingerprints in 'SHA certificate fingerprints' section"
echo "5. Download updated google-services.json"
echo ""
