# Localization Language List

This document lists the languages that should be supported for localization in order of priority.

## Priority Order

1. **English** (English)
   - Language Code: `en`
   - Region Code: `en-US` (default), `en-GB`, `en-AU`, etc.

2. **Chinese (Mandarin)** (中国語)
   - Language Code: `zh`
   - Region Code: `zh-CN` (Simplified), `zh-TW` (Traditional)

3. **Japanese** (日本語)
   - Language Code: `ja`
   - Region Code: `ja-JP`

4. **Korean** (朝鮮語／韓国語)
   - Language Code: `ko`
   - Region Code: `ko-KR`

5. **Hindi** (ヒンディー語)
   - Language Code: `hi`
   - Region Code: `hi-IN`

6. **Spanish** (スペイン語)
   - Language Code: `es`
   - Region Code: `es-ES`, `es-MX`, `es-AR`, etc.

7. **French** (フランス語)
   - Language Code: `fr`
   - Region Code: `fr-FR`, `fr-CA`, etc.

8. **Arabic** (アラビア語)
   - Language Code: `ar`
   - Region Code: `ar-SA`, `ar-EG`, etc.

9. **Bengali** (ベンガル語)
   - Language Code: `bn`
   - Region Code: `bn-BD`, `bn-IN`

10. **Russian** (ロシア語)
    - Language Code: `ru`
    - Region Code: `ru-RU`

11. **Portuguese** (ポルトガル語)
    - Language Code: `pt`
    - Region Code: `pt-BR`, `pt-PT`

12. **Urdu** (ウルドゥー語)
    - Language Code: `ur`
    - Region Code: `ur-PK`, `ur-IN`

13. **German** (ドイツ語)
    - Language Code: `de`
    - Region Code: `de-DE`, `de-AT`, `de-CH`

14. **Italian** (イタリア語)
    - Language Code: `it`
    - Region Code: `it-IT`

15. **Indonesian / Malay** (インドネシア語・マレー語)
    - Language Code: `id` (Indonesian), `ms` (Malay)
    - Region Code: `id-ID`, `ms-MY`

16. **Thai** (タイ語)
    - Language Code: `th`
    - Region Code: `th-TH`

## Implementation Notes

- **Base Language**: English (`en`) serves as the source language
- **RTL Support**: Arabic and Urdu require right-to-left text support
- **Character Sets**: Chinese, Japanese, Korean, Hindi, Bengali, Arabic, Urdu, and Thai use non-Latin scripts
- **Regional Variants**: Some languages have multiple regional variants that may require separate localization

## File Structure

For iOS localization, create `.xcstrings` files for each language:
- `Localizable.xcstrings` (main strings)
- `InfoPlist.xcstrings` (app metadata)
- Additional feature-specific `.xcstrings` files as needed

## Quality Assurance

- All translations should be reviewed by native speakers
- Cultural context should be considered for UI elements
- Date, time, and number formatting should follow regional conventions
- App Store metadata should be localized for each target market
