# Deployment Scripts

This directory contains scripts to help build and deploy the QTI Editor app.

## deploy.sh

Main deployment script that handles building, signing, and packaging.

### Usage

```bash
# Simple release build
./scripts/deploy.sh

# Clean build (removes previous build artifacts)
./scripts/deploy.sh --clean

# Build and create DMG installer
./scripts/deploy.sh --dmg

# Create archive (for Xcode Organizer)
./scripts/deploy.sh --archive

# Clean build with DMG
./scripts/deploy.sh --clean --dmg

# Show help
./scripts/deploy.sh --help
```

### What It Does

1. **Builds** the app in Release configuration
2. **Verifies** code signature
3. **Reports** app size and location
4. **Creates DMG** installer (if `--dmg` flag used)
5. **Shows** next steps for distribution

### Output Locations

- **App Bundle**: `./build/Build/Products/Release/QtiEditor.app`
- **Archive**: `./build/QtiEditor.xcarchive` (with `--archive`)
- **DMG**: `./QtiEditor-{version}.dmg` (with `--dmg`)

### Requirements

- macOS with Xcode installed
- Xcode Command Line Tools
- (Optional) `create-dmg` for prettier installers: `brew install create-dmg`

## Tips

### Quick Development Build
```bash
# For testing, use Xcode's Cmd+B or:
xcodebuild -project QtiEditor.xcodeproj -scheme QtiEditor -configuration Debug
```

### Production Release
```bash
# Full release with DMG
./scripts/deploy.sh --clean --dmg
```

### Share with Others
```bash
# Create DMG and share that file
./scripts/deploy.sh --dmg
# Share QtiEditor-1.0.dmg
```

## Troubleshooting

### "Command not found"
Make sure the script is executable:
```bash
chmod +x ./scripts/deploy.sh
```

### Build Fails
Check Xcode can build the project:
1. Open `QtiEditor.xcodeproj` in Xcode
2. Product → Build (Cmd+B)
3. Fix any errors shown in Xcode

### Code Signing Issues
Your project uses automatic signing. Ensure:
- You're signed into Xcode with your Apple ID
- Your team is selected in project settings
- Certificates are valid in Keychain Access

## See Also

- **DEPLOYMENT.md** - Comprehensive deployment guide
- **CLAUDE.md** - Project architecture documentation
