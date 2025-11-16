# Xcode Project Setup Instructions

## Required: Add Entitlements File

To fix file access issues with Open/Save dialogs, you need to add the entitlements file to your Xcode project:

### Steps:

1. **Open the project in Xcode**
   - Open `QtiEditor.xcodeproj`

2. **Select the QtiEditor target**
   - In the project navigator, click on the blue "QtiEditor" project
   - Select the "QtiEditor" target in the main editor

3. **Add the entitlements file**
   - Go to the "Signing & Capabilities" tab
   - Under "Signing", look for "Entitlements File"
   - Click the dropdown and select "QtiEditor/QtiEditor.entitlements"

   **OR** manually add it:
   - In "Build Settings" tab
   - Search for "Code Signing Entitlements"
   - Set the value to: `QtiEditor/QtiEditor.entitlements`

4. **Verify the settings**
   - The entitlements file should now appear in the project
   - It contains:
     - `com.apple.security.files.user-selected.read-write` - Allow file access
     - `com.apple.security.app-sandbox` set to `false` - Disable sandboxing for personal use

## Why This Is Needed

- **Save Panel Crash**: Without proper entitlements, NSSavePanel will crash
- **File Access**: The app needs permission to read and write .imscc files selected by the user
- **Sandboxing**: We disable app sandboxing since this is a personal-use tool

## Alternative: If Issues Persist

If you still see crashes or permission errors:

1. **Check Code Signing**
   - Go to Signing & Capabilities
   - Ensure "Automatically manage signing" is checked
   - Or use your personal Apple ID for signing

2. **Disable Hardened Runtime** (if needed)
   - In Signing & Capabilities
   - Remove or disable "Hardened Runtime" if present

3. **Clean Build**
   - Product → Clean Build Folder (Cmd+Shift+K)
   - Rebuild the project

## Errors You Should No Longer See

After adding entitlements:
- ✅ "Unable to display save panel" - Fixed
- ✅ "User Selected File Read entitlement but needs Read/Write" - Fixed
- ✅ Save panel crash on line 84 - Fixed
- ✅ "zip I/O error: Operation not permitted" - Fixed (zip now creates files in temp directory first)

## Known Harmless Warnings

**"Unable to obtain a task name port right for pid XXX: (os/kern) failure (0x5)"**

This is a harmless macOS system message that appears when:
- NSOpenPanel or NSSavePanel is displayed
- AppKit file dialogs interact with the system
- Debugging is active in Xcode

**Why it happens:**
- macOS uses "task ports" for inter-process communication
- File panels run in a separate security context
- The debugger can't fully access these secure panels
- This is by design for security purposes

**Impact:**
- ⚠️ Informational only - does not affect functionality
- File dialogs work correctly despite this message
- You can safely ignore this warning
- It will not appear in Release builds outside of Xcode

**To reduce clutter in console:**
- Uncheck "All Output" in Xcode console filter
- Or use console filter to hide these specific messages
- They won't appear to end users
