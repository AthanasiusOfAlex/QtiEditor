## Info.plist customization

If you want to add extra key-value pairs to your app’s Info.plist, you can specify them in the app’s plist field. Here’s an example configuration that appends the current commit hash to the version string displayed in the About HelloWorld screen of the HelloWorld app.

``` toml
# ...

[apps.HelloWorld.plist]

CFBundleShortVersionString = "$(VERSION)_$(COMMIT_HASH)"
```

Patterns of the form \$(...) get replaced with their corresponding values. See “Variable substitutions” below.

If you provide a value for a key that is already present in the default Info.plist, the default value will be overridden with the value you provide.

### Type ambiguity

Certain Property List field types such as data, date, and integer can’t be distinguished using TOML syntax alone. Swift Bundler will throw an error if any values cannot be decoded unambiguously.

To disambiguate, you can convert the value to a TOML dictionary with separate type and value fields. For this reason, dictionaries with a type field also require disambiguation.

| **Property List field type** | **Requires disambiguation?** | **Example** |
|:---|:---|:---|
| `string` | no | `MyKey = "My string"` |
| `boolean` | no | `MyKey = true` |
| `array` | no | `MyKey = [1, "A string"]` |
| `real` | no, *unless a whole number* | `MyKey = 1.2 or MyKey = { type = "real", value = 1.0 }` |
| `integer` | no | `MyKey = 1` |
| `date` | **yes** | `MyKey = { type = "date", value = "2024-12-02T10:08:00Z" }` |
| `data` | **yes** | `MyKey = { type = "data", value = "b3R0ZXIncyBpbiBhIHN0YWNrPw=="` }, must be base64 encoded |
| `dict` | no, *unless it contains a *type* key* | `MyKey = { major = 1, minor = 0 }` or `MyKey = { type = "dict", value = { type = 1, tag = 0 } }` |

## Variable substitutions

Some configuration fields (currently only plist) support variable substitution. This means that anything of the form \$(VARIABLE) within the field’s value will be replaced by the variable’s value. Below is a list of all supported variables.

| **Name** | **Value** |
|:---|:---|
| VERSION | The app’s version |
| COMMIT_HASH | The commit hash of the git repository at the package’s root directory. If there is no git repository, an error will be thrown. |
