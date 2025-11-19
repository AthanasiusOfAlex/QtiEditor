# Quick Start - Deployment

## TL;DR - Get Your App Running

### For Personal Use (Fastest)

```bash
# 1. Build release version
./scripts/deploy.sh --clean

# 2. Copy to Applications
cp -R ./build/Build/Products/Release/QtiEditor.app /Applications/

# 3. Run it
open /Applications/QtiEditor.app
```

If you see a security warning: **Right-click** → **Open** → **Open**

### For Sharing with Others

```bash
# Create a DMG installer
./scripts/deploy.sh --clean --dmg

# Share the file: QtiEditor-1.0.dmg
```

## One-Line Builds

```bash
# Debug build (fast, for testing)
xcodebuild -project QtiEditor.xcodeproj -scheme QtiEditor -configuration Debug

# Release build (optimized, for use)
xcodebuild -project QtiEditor.xcodeproj -scheme QtiEditor -configuration Release

# With custom output location
xcodebuild -project QtiEditor.xcodeproj -scheme QtiEditor -configuration Release -derivedDataPath ./build
```

## Using Xcode GUI

1. Open `QtiEditor.xcodeproj`
2. Select **Any Mac** in toolbar
3. **Product** → **Archive** (Cmd+Shift+B)
4. In Organizer: **Distribute App** → **Copy App**
5. Choose destination folder
6. Done! Your app is ready

## Common Issues - Quick Fixes

### "App is damaged"
```bash
xattr -cr /Applications/QtiEditor.app
```

### "Can't be opened because developer cannot be verified"
- Right-click the app
- Click **Open**
- Click **Open** again in dialog

### Build Fails
```bash
# Clean build folder
rm -rf ./build
xcodebuild clean -project QtiEditor.xcodeproj -scheme QtiEditor

# Try again
./scripts/deploy.sh --clean
```

## File Locations

| What | Where |
|------|-------|
| Source Code | `./QtiEditor/` |
| Xcode Project | `./QtiEditor.xcodeproj` |
| Build Output | `./build/Build/Products/Release/QtiEditor.app` |
| DMG Installer | `./QtiEditor-{version}.dmg` |
| Deployment Script | `./scripts/deploy.sh` |

## Deployment Checklist

- [ ] Run tests: `Cmd+U` in Xcode
- [ ] Build release: `./scripts/deploy.sh --clean`
- [ ] Test the built app
- [ ] Create DMG: `./scripts/deploy.sh --dmg`
- [ ] Test DMG installation
- [ ] Tag version: `git tag v1.0`
- [ ] Share or deploy

## Version Bumping

```bash
# In Xcode: Select project → Target → General → Version
# Or update in project.pbxproj manually
```

## Security Note

Current setup uses **development signing** (Apple Development certificate).

- **Works on**: Your Mac(s) where you're signed in with your Apple ID
- **Sharing**: Recipients may see security warning (they can bypass)
- **For wider distribution**: Get Developer ID certificate ($99/year Apple Developer Program)

## Need More Details?

- **Full guide**: See `DEPLOYMENT.md`
- **Script help**: Run `./scripts/deploy.sh --help`
- **Architecture**: See `CLAUDE.md`
