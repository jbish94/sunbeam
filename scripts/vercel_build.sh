#!/usr/bin/env bash
set -exo pipefail

# Validate required environment variables before doing any work
if [ -z "${SUPABASE_URL:-}" ]; then
  echo "ERROR: SUPABASE_URL is not set. Add it in Vercel → Settings → Environment Variables."
  exit 1
fi
if [ -z "${SUPABASE_ANON_KEY:-}" ]; then
  echo "ERROR: SUPABASE_ANON_KEY is not set. Add it in Vercel → Settings → Environment Variables."
  exit 1
fi

git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PWD/flutter/bin:$PATH"
flutter --version
flutter config --enable-web
flutter precache --web
flutter pub get
flutter build web --release \
  --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}" \
  --dart-define=OPENWEATHER_API_KEY="${OPENWEATHER_API_KEY:-}"
