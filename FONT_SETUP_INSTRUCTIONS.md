# Suisse Int'l Font Setup Instructions

## Overview
The application is now configured to use **Suisse Int'l** as the default font family throughout the entire app.

## Font Files Required

You need to add the following Suisse Int'l font files to the `assets/fonts/` directory:

1. **SuisseIntl-Regular.ttf** - Regular weight (400)
2. **SuisseIntl-Medium.ttf** - Medium weight (500)
3. **SuisseIntl-SemiBold.ttf** - Semi-bold weight (600)
4. **SuisseIntl-Bold.ttf** - Bold weight (700)

## Setup Steps

1. **Obtain the font files** from your font provider or design team
2. **Place the font files** in the `assets/fonts/` directory:
   ```
   assets/
     fonts/
       SuisseIntl-Regular.ttf
       SuisseIntl-Medium.ttf
       SuisseIntl-SemiBold.ttf
       SuisseIntl-Bold.ttf
   ```

3. **Run `flutter pub get`** to update dependencies

4. **Hot restart** the app (not just hot reload) for font changes to take effect

## Font Configuration

The font is configured in:
- `pubspec.yaml` - Font file declarations
- `lib/utils/app_theme.dart` - Default font family and all text styles

## What's Been Updated

✅ ThemeData now uses 'Suisse Int\'l' as the default font family
✅ All AppTheme text styles (heading1, heading2, bodyText, etc.) use Suisse Int'l
✅ All button text styles use Suisse Int'l
✅ All input field labels and hints use Suisse Int'l
✅ AppBar titles use Suisse Int'l
✅ All Material Design text themes use Suisse Int'l

## Troubleshooting

If the font doesn't appear:
1. Verify font files are in `assets/fonts/` directory
2. Check that file names match exactly (case-sensitive)
3. Run `flutter clean` then `flutter pub get`
4. Do a full app restart (not hot reload)
5. Check console for font loading errors

## Note

The font family name in code is `'Suisse Int\'l'` (with escaped apostrophe). Make sure your font files are properly named and the font family name in the font files matches this.

