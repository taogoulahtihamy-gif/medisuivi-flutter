#!/usr/bin/env bash
# Build only the ORIGINAL MediSuivi Flutter UI for a remote HTTPS sandbox.
set -euo pipefail
cd "$(dirname "$0")/.."

: "${MEDISUIVI_API_BASE_URL:?Set the public HTTPS API origin in Render}"
python3 scripts/check_remote_api_url.py "$MEDISUIVI_API_BASE_URL"

FLUTTER_VERSION="3.47.7"
if command -v flutter >/dev/null 2>&1; then
  INSTALLED="$(flutter --version --machine |
    python3 -c 'import json,sys; print(json.load(sys.stdin)["frameworkVersion"])')"
  if [ "$INSTALLED" != "$FLUTTER_VERSION" ]; then
    echo "Flutter version mismatch: expected $FLUTTER_VERSION" >&2
    exit 1
  fi
else
  FLUTTER_HOME="${HOME}/.cache/medisuivi-flutter-$FLUTTER_VERSION"
  if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
    mkdir -p "$(dirname "$FLUTTER_HOME")"
    git clone --depth 1 --branch "$FLUTTER_VERSION" \
      https://github.com/flutter/flutter.git "$FLUTTER_HOME"
  fi
  export PATH="$FLUTTER_HOME/bin:$PATH"
fi
flutter config --no-analytics
flutter precache --web
flutter pub get
flutter build web --release --no-pub \
  --dart-define="MEDISUIVI_DEV_API_BASE_URL=$MEDISUIVI_API_BASE_URL" \
  --dart-define=MEDISUIVI_REMOTE_SANDBOX=true

test -s build/web/index.html
test -s build/web/flutter_bootstrap.js
echo "MediSuivi web sandbox built for HTTPS API (no local backend)."
