# QTI Editor - Icon Guide

## Recommended Icon Design

### Concept
A quiz/questionnaire icon that represents:
- Multiple choice questions (primary feature)
- Document editing (core functionality)
- Professional, educational aesthetic

### Design Suggestions

**Option 1: Quiz Document**
```
┌─────────────┐
│  ◉ A) ...   │  Document with multiple-choice
│  ○ B) ...   │  radio buttons/bubbles
│  ○ C) ...   │
│  ○ D) ...   │  Colors: Blue gradient
└─────────────┘
```

**Option 2: Checkmark List**
```
┌─────────────┐
│  ✓  ─────   │  Checklist/quiz items
│  ○  ─────   │  with checkmarks
│  ○  ─────   │
│  ○  ─────   │  Colors: Purple/blue
└─────────────┘
```

**Option 3: "Q" Monogram**
```
┌─────────────┐
│             │
│      Q      │  Large "Q" with pencil
│     /✎      │  overlay or edit indicator
│             │  Colors: Teal/blue gradient
└─────────────┘
```

## Technical Specifications

### macOS App Icon Requirements
- **Master Size**: 1024×1024 pixels
- **Format**: PNG (with transparency)
- **Color Space**: sRGB or Display P3
- **Shape**: Square (macOS applies corner rounding)
- **Style**: Avoid gradients that are too subtle (won't show at small sizes)

### Required Icon Sizes
The .icns file needs these sizes:
- 16×16 (icon_16x16.png, icon_16x16@2x.png)
- 32×32 (icon_32x32.png, icon_32x32@2x.png)
- 64×64 (icon_64x64.png, icon_64x64@2x.png)
- 128×128 (icon_128x128.png, icon_128x128@2x.png)
- 256×256 (icon_256x256.png, icon_256x256@2x.png)
- 512×512 (icon_512x512.png, icon_512x512@2x.png)
- 1024×1024 (icon_1024x1024.png, icon_1024x1024@2x.png)

### macOS Design Guidelines
- **Recognizable**: Should be identifiable at 16×16px
- **Simple**: Avoid too much detail
- **Centered**: Main element should be centered
- **Padding**: Leave ~10% margin from edges
- **3D/Flat**: Modern macOS prefers subtle depth, not flat
- **Color**: Use distinctive colors that stand out in Dock

## Color Palette Suggestions

### Educational Blue (Recommended)
- Primary: `#4A90E2` (bright blue)
- Secondary: `#357ABD` (darker blue)
- Accent: `#5BC0DE` (light blue)

### Canvas LMS Brand Colors (Alternative)
- Primary: `#E13F34` (Canvas red)
- Secondary: `#0B874B` (Canvas green)
- Note: Use sparingly, users may not want Canvas branding

### Purple Gradient (Modern)
- Primary: `#667EEA` (purple-blue)
- Secondary: `#764BA2` (deep purple)
- Gives modern, professional feel

## How to Create the Icon

### Option 1: Using Figma (Free, Online)
1. Go to figma.com and create free account
2. Create new file: 1024×1024 artboard
3. Design your icon using shapes and text
4. Export as PNG (2x resolution for crisp edges)
5. Use online tool to generate .icns from PNG

### Option 2: Using SF Symbols (Quick)
1. Open SF Symbols app (free from Apple)
2. Find icon like: `list.bullet.circle`, `doc.text.fill`, `checkmark.circle`
3. Export as PNG at 1024×1024
4. Customize colors in Preview or Figma
5. Generate icon set

### Option 3: AI Generation
Example prompt for DALL-E/Midjourney:
```
"macOS app icon for a quiz editor application,
showing multiple choice questions with bubbles
marked A B C D, clean modern design, blue and
purple gradient, professional, minimalist,
1024x1024, app icon style"
```

### Option 4: Hire a Designer
- **Fiverr**: $10-50 for simple app icon
- **99designs**: Icon contest, $299+
- **Upwork**: Hire designer hourly

## Converting to .icns Format

### Using iconutil (macOS Built-in)
```bash
# 1. Create icon set directory
mkdir MyIcon.iconset

# 2. Add all required sizes (16, 32, 64, 128, 256, 512, 1024)
# Named as: icon_16x16.png, icon_16x16@2x.png, etc.

# 3. Generate .icns file
iconutil -c icns MyIcon.iconset -o AppIcon.icns
```

### Using Image2icon (Free App)
1. Download Image2icon from Mac App Store (free)
2. Drag your 1024×1024 PNG onto the app
3. It generates all sizes automatically
4. Export as .icns

### Using ImageMagick (Command Line)
```bash
# Install via Homebrew
brew install imagemagick

# Convert PNG to ICNS
convert icon-1024.png -define icon:auto-resize=1024,512,256,128,64,32,16 AppIcon.icns
```

## Adding Icon to Xcode Project

Once you have your icon:

1. **Open Asset Catalog**
   - In Xcode: Navigate to `QtiEditor/Resources/Assets.xcassets`
   - Click on `AppIcon`

2. **Add Icon Images**
   - Drag 1024×1024 PNG to "Mac 1024pt" slot
   - Or drag .icns file to import all sizes
   - Xcode will validate and show any missing sizes

3. **Verify**
   - Build the project
   - Check icon appears in build product
   - Test: `qlmanage -t ./build/Build/Products/Release/QtiEditor.app`

## Temporary Solution: SF Symbols Icon

For development, you can use SF Symbols:

In `QtiEditor/App/QtiEditorApp.swift`, you can reference system icons:
```swift
WindowGroup {
    ContentView()
}
.defaultAppStorage(.standard)
.windowStyle(.titleBar)
// Uses system icon until custom icon added
```

## Testing Your Icon

```bash
# Build the app
xcodebuild -project QtiEditor.xcodeproj -scheme QtiEditor -configuration Release

# View icon in Finder
open ./build/Build/Products/Release/

# Quick Look the app to see icon
qlmanage -t ./build/Build/Products/Release/QtiEditor.app
```

## Recommended Next Steps

1. **Sketch a design** - Draw rough concept on paper
2. **Choose tool** - Pick Figma, SF Symbols, or AI generation
3. **Create 1024×1024 PNG** - Master icon file
4. **Generate icon set** - Use iconutil or Image2icon
5. **Add to Xcode** - Drag to Assets.xcassets
6. **Build and test** - Verify icon appears correctly

## Resources

- **SF Symbols**: https://developer.apple.com/sf-symbols/
- **Human Interface Guidelines**: https://developer.apple.com/design/human-interface-guidelines/app-icons
- **Figma**: https://www.figma.com
- **Image2icon**: Mac App Store (search "Image2icon")
- **Icon design inspiration**: https://www.macosicongallery.com/

---

**Need help adding the icon once you have it? Let me know!**
