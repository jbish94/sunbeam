# Sunbeam ☀️

A Flutter app for tracking sun exposure: live UV index and weather for your location, session logging with mood/energy tracking, goals, and insights. Backed by Supabase (auth + Postgres with row-level security) and OpenWeather.

## Prerequisites

- Flutter SDK 3.29+ (stable channel)
- Xcode (for iOS) / Android Studio (for Android)
- A Supabase project (URL + anon key)
- An OpenWeather API key (https://openweathermap.org/api) — the hourly UV chart additionally requires One Call API access

## Configuration

All secrets are injected at build time via `--dart-define-from-file`. Copy the template and fill in your values (`env.json` is gitignored):

```json
{
  "SUPABASE_URL": "https://YOUR-PROJECT.supabase.co",
  "SUPABASE_ANON_KEY": "YOUR-ANON-KEY",
  "OPENWEATHER_API_KEY": "YOUR-OPENWEATHER-KEY"
}
```

Apply the database migrations in `supabase/migrations/` to your Supabase project (e.g. `supabase db push`). The latest migration also creates the `delete_account()` RPC required for in-app account deletion.

## Running

```bash
flutter pub get
flutter run --dart-define-from-file=env.json
```

## Building for release

```bash
# iOS (App Store)
flutter build ipa --release --dart-define-from-file=env.json

# Android
flutter build appbundle --release --dart-define-from-file=env.json

# Web (Vercel uses scripts/vercel_build.sh with env vars from project settings)
flutter build web --release --dart-define-from-file=env.json
```

## App Store submission checklist

Project-side items already configured: bundle ID `com.sunbeam.app`, app icons, privacy manifest (`PrivacyInfo.xcprivacy`), portrait-only orientation, location usage descriptions, deep-link scheme `io.supabase.sunbeam://login-callback/` for auth emails, in-app Privacy Policy / Terms / Medical Disclaimer, and in-app account deletion.

Remaining items to do in App Store Connect / external services:

1. Register the App ID `com.sunbeam.app` in your Apple Developer account and create the app in App Store Connect.
2. Host the legal documents (sources in `assets/legal/`) on a public URL and set the Privacy Policy URL in App Store Connect.
3. Fill out the App Privacy questionnaire (the app collects: email, name, precise location, health & fitness data — all linked to identity, none used for tracking).
4. In the Supabase dashboard: add `io.supabase.sunbeam://login-callback/` to Auth → URL Configuration → Redirect URLs.
5. Ensure `OPENWEATHER_API_KEY` is provided to all release builds — without it the app runs but shows "weather unavailable".
6. Confirm the test accounts (`admin@sunbeam.com`, `user@sunbeam.com`) were removed from production by applying the latest migration.

## Project structure

```
lib/
├── core/             # Shared exports
├── presentation/     # Screens and widgets (home, log session, insights, profile, …)
├── routes/           # Route table (lib/routes/app_routes.dart)
├── services/         # Supabase, location, weather, session services
├── theme/            # Light/dark themes
└── main.dart         # Entry point
assets/legal/         # Privacy Policy, Terms, Medical Disclaimer (markdown)
supabase/migrations/  # Database schema + RLS policies
```
