#!/bin/bash

# Script to create Android keystore for Play Store signing
# This will prompt you for passwords - use strong passwords and keep them safe!

echo "Creating Android keystore for Play Store signing..."
echo "You will be prompted for:"
echo "  - Keystore password (min 6 characters)"
echo "  - Key password (can be same as keystore password)"
echo ""

cd "$(dirname "$0")"

/Applications/Android\ Studio.app/Contents/jbr/Contents/Home/bin/keytool \
  -genkey \
  -v \
  -keystore upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload \
  -storetype JKS \
  -dname "CN=Ahadi, OU=Development, O=Quantum Vision Tech, L=City, ST=State, C=KE"

if [ $? -eq 0 ]; then
  echo ""
  echo "✓ Keystore created successfully!"
  echo ""
  echo "Next steps:"
  echo "1. Update android/key.properties with your keystore password"
  echo "2. Keep your keystore file and passwords safe - you'll need them for all future releases!"
  echo "3. Build your release APK/AAB with: flutter build appbundle --release"
else
  echo ""
  echo "✗ Failed to create keystore. Please try again."
fi
