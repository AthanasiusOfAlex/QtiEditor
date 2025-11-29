# Info.plist Customization in Bundler.toml

## Quick Reference

Add custom Info.plist entries in the `[apps.YourAppName.plist]` section of your Bundler.toml file.

## Basic Syntax

```toml
[apps.QtiEditor.plist]
KeyName = value
```

## Supported Data Types

### Simple Types (No Disambiguation Needed)

| Type | Example |
|------|---------|
| **String** | `MyKey = "Hello World"` |
| **Boolean** | `NSAutosaveInPlace = false` |
| **Integer** | `MaxItems = 100` |
| **Array** | `MyArray = [1, 2, "string"]` |
| **Float** | `MyFloat = 1.5` (decimals required) |
| **Dictionary** | `MyDict = { key1 = "value", key2 = 123 }` |

### Complex Types (Disambiguation Required)

For ambiguous types, use the expanded syntax with `type` and `value` fields:

```toml
# Date
ReleaseDate = { type = "date", value = "2024-12-02T10:08:00Z" }

# Data (base64 encoded)
BinaryData = { type = "data", value = "b3R0ZXIncyBpbiBhIHN0YWNrPw==" }

# Float (when value is a whole number)
MyFloat = { type = "real", value = 1.0 }

# Dictionary (if it contains a 'type' key)
MyDict = { type = "dict", value = { type = 1, tag = 0 } }
```

## Arrays of Dictionaries

Use TOML's double-bracket syntax for repeated entries:

```toml
[[apps.QtiEditor.plist.CFBundleDocumentTypes]]
CFBundleTypeName = "Canvas QTI Package"
LSHandlerRank = "Owner"
LSItemContentTypes = ["org.imsglobal.imscc"]

[[apps.QtiEditor.plist.UTExportedTypeDeclarations]]
UTTypeConformsTo = ["public.zip-archive"]
UTTypeDescription = "Canvas QTI Package"
UTTypeIdentifier = "org.imsglobal.imscc"
UTTypeTagSpecification = { "public.filename-extension" = ["imscc"] }
```

## Variable Substitution

Use `$(VARIABLE)` syntax for dynamic values:

```toml
CFBundleShortVersionString = "$(VERSION)_$(COMMIT_HASH)"
```

**Available Variables:**
- `$(VERSION)` - The app's version field
- `$(COMMIT_HASH)` - Git commit hash (requires git repository)

## Important Notes

1. **Override Behavior**: Custom values replace default Info.plist values for the same key
2. **Type Safety**: Swift Bundler will error on ambiguous types - use disambiguation syntax when needed
3. **Preservation**: Existing Info.plist keys not specified in Bundler.toml remain unchanged

## Example from QtiEditor

```toml
[apps.QtiEditor.plist]
NSAutosaveInPlace = false

[[apps.QtiEditor.plist.CFBundleDocumentTypes]]
CFBundleTypeName = "Canvas QTI Package"
LSHandlerRank = "Owner"
LSItemContentTypes = ["org.imsglobal.imscc"]

[[apps.QtiEditor.plist.UTExportedTypeDeclarations]]
UTTypeConformsTo = ["public.zip-archive"]
UTTypeDescription = "Canvas QTI Package"
UTTypeIdentifier = "org.imsglobal.imscc"
UTTypeTagSpecification = { "public.filename-extension" = ["imscc"] }
```
