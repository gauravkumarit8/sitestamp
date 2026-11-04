# Languages

The app interface is English or Hindi (हिन्दी). Switch in Settings (tune icon) or on the
first welcome screen. On first launch it follows the phone's language if that is Hindi.

## How it works
- Screens show text with `Tx('English text')` (or `tr('English text')` in code).
- `lib/l10n/hindi.dart` maps the exact English string to its Hindi text.
- A string with no entry simply stays in English, so nothing breaks.

## Add a string
Add `'English text': 'हिन्दी पाठ',` to `kHindi`. Keys must match the English exactly.

## Add another language
Copy hindi.dart (for example to gujarati.dart), translate the values, and extend
`AppLanguage` / `tr()` to pick the map for that code. Then add the language to the
two language selectors (settings sheet and onboarding screen).

## Not translated on purpose
Text printed ON the photo (month names, Lat/Lon, Alt, Accuracy, warnings) stays English
so reports are readable everywhere. Project names, notes, company details and
checklist steps are your own text and are never translated.

Please have a native Hindi speaker review the translations before a public release.
