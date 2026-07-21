#!/usr/bin/env bash
# Build Flutter web artifacts for all Receipt24 apps.
# Usage: ./scripts/build-web.sh [--app consumer|accountant|admin]

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT/build/web"
APP_FILTER="${1:-all}"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK is required. Install: https://flutter.dev/docs/get-started/install" >&2
  exit 1
fi

build_app() {
  local name="$1"
  local dir="$2"
  local out="$BUILD_DIR/$name"

  echo "==> Building $name ($dir)..."
  cd "$ROOT/$dir"
  flutter pub get
  flutter build web \
    --release \
    --base-href "/" \
    --dart-define=FLUTTER_WEB_USE_SKIA=true \
    -o "$out"
  echo "    Output: $out"
}

mkdir -p "$BUILD_DIR"

# Ensure .env files exist (CI should run inject-env.sh first).
if [[ ! -f "$ROOT/apps/consumer/.env" ]]; then
  echo "Warning: apps/consumer/.env missing — run ./scripts/inject-env.sh first" >&2
fi

case "$APP_FILTER" in
  --app)
    shift
    case "${1:-}" in
      consumer) build_app consumer apps/consumer ;;
      accountant) build_app accountant apps/accountant_portal ;;
      admin) build_app admin apps/admin_dashboard ;;
      *) echo "Unknown app: $1" >&2; exit 1 ;;
    esac
    ;;
  all)
    build_app consumer apps/consumer
    build_app accountant apps/accountant_portal
    build_app admin apps/admin_dashboard
    ;;
  *)
    echo "Usage: $0 [--app consumer|accountant|admin]" >&2
    exit 1
    ;;
esac

echo "==> Web builds complete in $BUILD_DIR"
