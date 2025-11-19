# QTI Editor - Deployment Guide

This guide covers how to build, bundle, and deploy the QTI Editor app for macOS.

## Project Configuration Summary

- **Bundle ID**: `com.AthanasiusOfAlex.QtiEditor`
- **Development Team**: `548VGSQ8QK`
- **Deployment Target**: macOS 14.0 (Sequoia)
- **Code Signing**: Automatic (Apple Development)
- **Current Version**: 1.0
- **Build**: 1

## Prerequisites

### Required
- **macOS Sequoia** (14.0 or later)
- **Xcode 26.1.1** or later
- **Apple ID** with Developer Program membership (or free Apple ID for local development)

### Your Configured Settings
Your project is already configured with:
- App Sandbox: **Disabled** (for personal use - easier file access)
- User Selected Files: **Read/Write** permissions
- Network Client: **Enabled** (for future features)
- Code Sign Style: **Automatic**

## Building the App

### 1. Quick Build (Debug)

For development and testing:

```bash
# Open the project
open QtiEditor.xcodeproj

# Or build from command line
xcodebuild -project QtiEditor.xcodeproj \
           -scheme QtiEditor \
           -configuration Debug \
           -derivedDataPath ./build
```

**Result**: Debug build at `./build/Build/Products/Debug/QtiEditor.app`

### 2. Release Build

For production use:

```bash
xcodebuild -project QtiEditor.xcodeproj \
           -scheme QtiEditor \
           -configuration Release \
           -derivedDataPath ./build
```

**Result**: Optimized build at `./build/Build/Products/Release/QtiEditor.app`

## Deployment Options

### Option 1: Direct Use (Simplest)

**Best for**: Personal use on your own Mac

1. Build in **Release** configuration (Cmd+Shift+R in Xcode)
2. Navigate to build products:
   - In Xcode: Product → Show Build Folder in Finder
   - Or: `./build/Build/Products/Release/`
3. Copy `QtiEditor.app` to `/Applications` (or anywhere you like)
4. Run the app

**First Launch**: Right-click → Open (to bypass Gatekeeper warning)

### Option 2: Archive & Export (Recommended)

**Best for**: Sharing with others or multiple Macs

#### Step 1: Create Archive

In Xcode:
1. Select **Any Mac** as destination (top toolbar)
2. Product → Archive (or Cmd+Shift+B)
3. Wait for archive to complete
4. Organizer window will open automatically

Or via command line:
```bash
xcodebuild archive \
    -project QtiEditor.xcodeproj \
    -scheme QtiEditor \
    -archivePath ./build/QtiEditor.xcarchive
```

#### Step 2: Export Archive

In Xcode Organizer:
1. Select your archive
2. Click **Distribute App**
3. Choose export method:

**For Personal Use:**
- Select **Copy App**
- Click **Next**
- Choose destination folder
- Click **Export**

**Result**: Signed `.app` bundle ready to use

#### Step 3: Code Signing Options

Your project uses **Automatic** signing with your development team. You have three options:

##### A. Development Signing (Current Setup)
- **What it is**: Apple Development certificate (already configured)
- **Good for**: Your own Macs
- **Limitations**: May show warning on first launch
- **Bypass**: Right-click → Open

##### B. Developer ID Signing (For Distribution)
- **What it is**: Developer ID Application certificate
- **Good for**: Sharing with others
- **Requirements**: Paid Apple Developer Program ($99/year)
- **Setup**:
  1. Get Developer ID certificate from Apple Developer portal
  2. In Xcode: Change code signing to **Developer ID**
  3. Archive and export with Developer ID
- **Benefit**: No Gatekeeper warning on other Macs

##### C. Notarization (Optional - Most Trusted)
- **What it is**: Apple's malware scanning service
- **Requirements**: Developer ID + paid Apple Developer Program
- **Benefit**: Zero warnings on any Mac
- **Process**:
  1. Export with Developer ID
  2. Submit to Apple for notarization
  3. Staple notarization ticket to app

**For personal use, Option A (current setup) is fine.**

## Creating a DMG Installer (Optional)

For professional distribution:

### Using hdiutil (Built-in)

```bash
#!/bin/bash
# Create a DMG from your app

APP_NAME="QtiEditor"
VERSION="1.0"
SOURCE_APP="./build/Build/Products/Release/${APP_NAME}.app"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
VOLUME_NAME="${APP_NAME} ${VERSION}"

# Create temporary directory
mkdir -p ./dmg-staging
cp -R "${SOURCE_APP}" ./dmg-staging/

# Create DMG
hdiutil create -volname "${VOLUME_NAME}" \
               -srcfolder ./dmg-staging \
               -ov \
               -format UDZO \
               "${DMG_NAME}"

# Cleanup
rm -rf ./dmg-staging

echo "✅ DMG created: ${DMG_NAME}"
```

Save as `create-dmg.sh`, make executable (`chmod +x create-dmg.sh`), and run.

### Using create-dmg (Fancy)

For a prettier DMG with custom background and layout:

```bash
# Install create-dmg (if you have Homebrew)
brew install create-dmg

# Create beautiful DMG
create-dmg \
  --volname "QTI Editor 1.0" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "QtiEditor.app" 175 190 \
  --hide-extension "QtiEditor.app" \
  --app-drop-link 425 190 \
  "QtiEditor-1.0.dmg" \
  "./build/Build/Products/Release/QtiEditor.app"
```

## Distribution Methods

### Method 1: Direct Copy
Simply copy `QtiEditor.app` to `/Applications` on target Mac.

### Method 2: AirDrop
Right-click the `.app` → Share → AirDrop to another Mac.

### Method 3: ZIP Archive
```bash
cd ./build/Build/Products/Release
zip -r QtiEditor-1.0.zip QtiEditor.app
```

Send the ZIP file. Recipients can unzip and drag to Applications.

### Method 4: DMG (Recommended for Sharing)
Create DMG (see above), share the `.dmg` file.

## Version Management

### Updating Version Numbers

Edit these in Xcode target settings:
- **Marketing Version**: `1.0` → `1.1` (user-facing version)
- **Build Number**: `1` → `2` (incremental build)

Or via command line:
```bash
# Update marketing version
xcrun agvtool new-marketing-version 1.1

# Update build number
xcrun agvtool next-version -all
```

### Git Tagging

Tag releases for version control:
```bash
git tag -a v1.0 -m "Release version 1.0"
git push origin v1.0
```

## Troubleshooting

### "App is damaged and can't be opened"

This happens when downloading from internet. Fix:
```bash
xattr -cr /Applications/QtiEditor.app
```

### "App can't be opened because the developer cannot be verified"

Right-click the app → Open → Click "Open" in the dialog.

Or remove quarantine attribute:
```bash
xattr -d com.apple.quarantine /Applications/QtiEditor.app
```

### Code Signing Issues

Check signature:
```bash
codesign -vvv --deep --strict /Applications/QtiEditor.app
```

Re-sign if needed:
```bash
codesign --force --deep --sign "Apple Development" QtiEditor.app
```

### Check Entitlements

View current entitlements:
```bash
codesign -d --entitlements - /Applications/QtiEditor.app
```

## Recommended Workflow

### For Personal Use (You)
1. Build in Release configuration
2. Copy to `/Applications`
3. Done!

### For Sharing with Friends
1. Archive in Xcode
2. Export → Copy App
3. Create DMG
4. Share DMG file

### For Public Distribution (Requires Paid Dev Account)
1. Get Developer ID certificate
2. Archive with Developer ID signing
3. Notarize with Apple
4. Create DMG
5. Distribute

## File Locations Reference

```
Project Root/
├── QtiEditor.xcodeproj/          # Xcode project
├── QtiEditor/                     # Source code
│   ├── QtiEditor.entitlements    # App permissions
│   └── Resources/                # Icons, assets
├── build/                         # Build output (gitignored)
│   └── Build/Products/
│       ├── Debug/
│       │   └── QtiEditor.app     # Debug build
│       └── Release/
│           └── QtiEditor.app     # Release build
└── DerivedData/                   # Xcode cache (gitignored)
```

## Security Notes

### Current Configuration
- **App Sandbox**: Disabled for easier file access
- **User Selected Files**: Read/write permission
- **Network**: Client connections allowed

### For App Store (If Needed in Future)
Would need:
- Enable App Sandbox
- Remove broad file access
- Use security-scoped bookmarks
- Add specific entitlements

### Code Signing Identity
Your team ID (`548VGSQ8QK`) is already configured for automatic signing.

## Quick Reference Commands

```bash
# Build release version
xcodebuild -project QtiEditor.xcodeproj -scheme QtiEditor -configuration Release

# Create archive
xcodebuild archive -project QtiEditor.xcodeproj -scheme QtiEditor -archivePath ./build/QtiEditor.xcarchive

# Check code signature
codesign -vvv --deep --strict ./build/Build/Products/Release/QtiEditor.app

# Create simple DMG
hdiutil create -volname "QTI Editor" -srcfolder ./build/Build/Products/Release -ov -format UDZO QtiEditor.dmg

# Remove quarantine attribute
xattr -cr /path/to/QtiEditor.app
```

## Next Steps

1. **Test the build**: Build in Release mode and test all features
2. **Create deployment script**: Automate building + DMG creation
3. **Set up versioning**: Decide on version numbering scheme
4. **Documentation**: Add user guide for installation
5. **Consider notarization**: If sharing with many users

---

**Questions or Issues?**
Check the main README and CLAUDE.md for project architecture details.
