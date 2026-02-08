#!/bin/bash

# GitHub Release Creation Script for VibeSVN v1.1.0

# Configuration
REPO_OWNER="rvgroup"
REPO_NAME="vibesvn"
TAG="v1.1.0"
TITLE="VibeSVN v1.1.0: Advanced Filtering & UI Redesign"

# Check if GitHub token is set
if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ Error: GITHUB_TOKEN environment variable is not set"
    echo "Please set your GitHub token:"
    echo "export GITHUB_TOKEN=your_github_token_here"
    echo ""
    echo "Alternatively, create the release manually at:"
    echo "https://github.com/$REPO_OWNER/$REPO_NAME/releases/new?tag=$TAG"
    exit 1
fi

# Read and format release notes
RELEASE_NOTES_FILE="release/v1.1.0/RELEASE_NOTES.md"
if [ ! -f "$RELEASE_NOTES_FILE" ]; then
    echo "❌ Error: Release notes file not found: $RELEASE_NOTES_FILE"
    exit 1
fi

# Convert markdown to JSON-safe format
RELEASE_BODY=$(cat "$RELEASE_NOTES_FILE" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

# Create release
echo "🚀 Creating GitHub release for $TAG..."

RESPONSE=$(curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases \
  -d "{
    \"tag_name\": \"$TAG\",
    \"target_commitish\": \"main\",
    \"name\": \"$TITLE\",
    \"body\": \"$RELEASE_BODY\",
    \"draft\": false,
    \"prerelease\": false
  }")

# Check if release was created successfully
if echo "$RESPONSE" | grep -q '"html_url"'; then
    RELEASE_URL=$(echo "$RESPONSE" | grep -o '"html_url": "[^"]*' | cut -d'"' -f4)
    RELEASE_ID=$(echo "$RESPONSE" | grep -o '"id": [0-9]*' | cut -d':' -f2 | tr -d ' ')
    
    echo "✅ Release created successfully!"
    echo "🔗 Release URL: $RELEASE_URL"
    echo "📝 Release ID: $RELEASE_ID"
    
    # Upload assets
    echo ""
    echo "📦 Uploading release assets..."
    
    # Upload macOS zip
    MACOS_FILE="release/v1.1.0/vibesvn-v1.1.0-macos.zip"
    if [ -f "$MACOS_FILE" ]; then
        echo "🍎 Uploading macOS build..."
        UPLOAD_RESPONSE=$(curl -s -X POST \
          -H "Authorization: token $GITHUB_TOKEN" \
          -H "Content-Type: application/octet-stream" \
          https://uploads.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/$RELEASE_ID/assets?name=vibesvn-v1.1.0-macos.zip \
          --data-binary @"$MACOS_FILE")
        echo "✅ macOS build uploaded"
    fi
    
    # Upload Android APK
    ANDROID_FILE="release/v1.1.0/vibesvn-v1.1.0-android.apk"
    if [ -f "$ANDROID_FILE" ]; then
        echo "📱 Uploading Android build..."
        UPLOAD_RESPONSE=$(curl -s -X POST \
          -H "Authorization: token $GITHUB_TOKEN" \
          -H "Content-Type: application/octet-stream" \
          https://uploads.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/$RELEASE_ID/assets?name=vibesvn-v1.1.0-android.apk \
          --data-binary @"$ANDROID_FILE")
        echo "✅ Android build uploaded"
    fi
    
else
    echo "❌ Error creating release:"
    echo "$RESPONSE"
    echo ""
    echo "🔧 Manual creation link:"
    echo "https://github.com/$REPO_OWNER/$REPO_NAME/releases/new?tag=$TAG"
    exit 1
fi

echo ""
echo "🎉 VibeSVN v1.1.0 release is now live!"
echo "📥 Download links available at: $RELEASE_URL"
