# Xcode Project Localization Settings

This document provides step-by-step instructions for configuring localization in your Xcode project.

## 1. Add Localization Files to Xcode

### Add .xcstrings Files
1. Open your Xcode project
2. Right-click on the `Resources` folder in the project navigator
3. Select "Add Files to [ProjectName]"
4. Navigate to the `Resources` folder and select:
   - `Localizable.xcstrings`
   - `InfoPlist.xcstrings`
5. Make sure "Add to target" is checked for your main app target
6. Click "Add"

### Verify File References
- Ensure the files appear in the project navigator
- Check that they are included in your app target in the "Build Phases" tab

## 2. Configure Project Localization Settings

### Enable Localization
1. Select your project in the project navigator
2. Select your app target
3. Go to the "Info" tab
4. In the "Localizations" section, click the "+" button
5. Add the languages you want to support:
   - English (en)
   - Japanese (ja)
   - Chinese Simplified (zh-Hans)
   - German (de)
   - Spanish (es)
   - French (fr)
   - And others as needed

### Configure Localization Files
1. In the "Info" tab, expand "Localizations"
2. For each language, ensure the following files are checked:
   - `Localizable.xcstrings`
   - `InfoPlist.xcstrings`
3. Uncheck any old `.strings` files if they exist

## 3. Update Info.plist

### Add Localization Keys
Add the following keys to your `Info.plist`:

```xml
<key>CFBundleLocalizations</key>
<array>
    <string>en</string>
    <string>ja</string>
    <string>zh-Hans</string>
    <string>de</string>
    <string>es</string>
    <string>fr</string>
    <!-- Add other supported languages -->
</array>

<key>CFBundleDevelopmentRegion</key>
<string>en</string>
```

### Add Privacy Usage DeCriptions
Ensure you have the following privacy usage deCriptions:

```xml
<key>NSMicrophoneUsageDeCription</key>
<string>$(NSMicrophoneUsageDeCription)</string>
```

## 4. Update Build Settings

### Localization Settings
1. Select your project in the project navigator
2. Select your app target
3. Go to the "Build Settings" tab
4. Search for "Localization"
5. Set the following:
   - `LOCALIZATION_PREFERS_STRING_CATALOGS` = `YES`
   - `LOCALIZATION_EXPORT_STRINGS` = `YES`

### Swift Compiler Settings
1. In "Build Settings", search for "Swift Compiler"
2. Set the following:
   - `SWIFT_STRICT_CONCURRENCY` = `Complete` (if using Swift 6)

## 5. Update Code

### Replace Old Localization Calls
Replace old `NSLocalizedString` calls with `LocalizedStringResource`:

```swift
// Old way (remove)
Text(LocalizedStrings.History.title)

// New way (use)
Text(LocalizedStringsNew.History.title)
```

### Update App Structure
Update your main app file to use the new language manager:

```swift
@main
struct WhisperAXApp: App {
    @StateObject private var languageManager = LanguageManagerNew.shared
    // ... other properties
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(languageManager)
        }
    }
}
```

## 6. Test Localization

### Test in Simulator
1. Build and run your app
2. Go to Settings > General > Language & Region
3. Change the language to test
4. Launch your app to verify translations appear

### Test in Xcode
1. In Xcode, go to Product > Scheme > Edit Scheme
2. In the "Run" section, go to "Options"
3. Set "App Language" to different languages
4. Run the app to test each language

## 7. Add Translations

### Using Xcode's Localization Editor
1. Select a `.xcstrings` file in the project navigator
2. Xcode will open the localization editor
3. Add translations for each language
4. Use the "Extract" feature to find untranslated strings

### Manual Translation
1. Open the `.xcstrings` file in a text editor
2. Add translations in the `localizations` section:

```json
{
  "My String" : {
    "localizations" : {
      "en" : {
        "stringUnit" : {
          "state" : "translated",
          "value" : "My String"
        }
      },
      "ja" : {
        "stringUnit" : {
          "state" : "translated",
          "value" : "私の文字列"
        }
      }
    }
  }
}
```

## 8. Clean Up Old Files

### Remove Old .strings Files
After verifying the new system works:
1. Remove old `.lproj` directories
2. Remove old `.strings` files
3. Update any remaining references in code

### Update Build Scripts
If you have any build scripts that reference old localization files, update them to use the new `.xcstrings` files.

## 9. Verification Checklist

- [ ] `.xcstrings` files are added to the project
- [ ] Localizations are enabled in project settings
- [ ] Info.plist contains localization keys
- [ ] Build settings are configured correctly
- [ ] Code uses `LocalizedStringResource`
- [ ] App uses new `LanguageManagerNew`
- [ ] Translations are added for all supported languages
- [ ] App is tested in multiple languages
- [ ] Old localization files are removed

## Troubleshooting

### Strings Not Appearing
- Check that keys exist in `.xcstrings` files
- Verify files are added to the correct target
- Ensure localization is enabled in project settings

### Build Errors
- Check that all required files are added to the project
- Verify build settings are correct
- Ensure no old localization references remain

### Translation Issues
- Use Xcode's localization editor for better error detection
- Check JSON syntax in `.xcstrings` files
- Verify all required languages have translations
