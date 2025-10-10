#!/bin/bash

#chmod +x build-release.sh

echo "Building environment-switcher for ARM64..."

# Build for ARM64 (release mode)
swift build -c release

# Create release directory
mkdir -p release

# Copy binary
cp .build/release/switch release/switch

# Create tarball
cd release
tar -czf switch-arm64-apple-macos.tar.gz switch
SHA256=$(shasum -a 256 switch-arm64-apple-macos.tar.gz | cut -d ' ' -f 1)
cd ..

echo ""
echo "✓ Built switch-arm64-apple-macos.tar.gz"
echo ""
echo "SHA256: ${SHA256}"
