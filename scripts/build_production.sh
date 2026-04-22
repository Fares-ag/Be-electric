#!/usr/bin/env bash
# Release builds with OneSignal dart-defines.
# Usage (from repo root):
#   export ONE_SIGNAL_APP_ID=your-uuid
#   ./scripts/build_production.sh requestor
# Or create scripts/defines.production.json from defines.production.json.example

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEFINES_FILE="$SCRIPT_DIR/defines.production.json"

TARGET="${1:-both}"
ANDROID_FORMAT="${2:-apk}"

define_args=()
if [[ -f "$DEFINES_FILE" ]]; then
  echo "Using --dart-define-from-file: $DEFINES_FILE"
  define_args+=(--dart-define-from-file="$DEFINES_FILE")
else
  if [[ -z "${ONE_SIGNAL_APP_ID:-}" ]]; then
    echo "ERROR: Set ONE_SIGNAL_APP_ID or create $DEFINES_FILE (see defines.production.json.example)" >&2
    exit 1
  fi
  define_args+=(--dart-define="ONE_SIGNAL_APP_ID=$ONE_SIGNAL_APP_ID")
  [[ -n "${SUPABASE_URL:-}" ]] && define_args+=(--dart-define="SUPABASE_URL=$SUPABASE_URL")
  [[ -n "${SUPABASE_ANON_KEY:-}" ]] && define_args+=(--dart-define="SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY")
fi

build_android() {
  local app_subdir="$1"
  local format="$2"
  (
    cd "$REPO_ROOT/apps/$app_subdir"
    flutter build "$format" --release "${define_args[@]}"
  )
}

build_ios() {
  local app_subdir="$1"
  (
    cd "$REPO_ROOT/apps/$app_subdir"
    flutter build ipa --release "${define_args[@]}"
  )
}

case "$ANDROID_FORMAT" in
  apk|appbundle) ;;
  ipa) ;;
  *)
    echo "Second arg must be apk, appbundle, or ipa (got: $ANDROID_FORMAT)" >&2
    exit 1
    ;;
esac

case "$TARGET" in
  requestor)
    if [[ "$ANDROID_FORMAT" == "ipa" ]]; then build_ios requestor_cmms; else build_android requestor_cmms "$ANDROID_FORMAT"; fi
    ;;
  technician)
    if [[ "$ANDROID_FORMAT" == "ipa" ]]; then build_ios technician_cmms; else build_android technician_cmms "$ANDROID_FORMAT"; fi
    ;;
  both)
    if [[ "$ANDROID_FORMAT" == "ipa" ]]; then
      build_ios requestor_cmms
      build_ios technician_cmms
    else
      build_android requestor_cmms "$ANDROID_FORMAT"
      build_android technician_cmms "$ANDROID_FORMAT"
    fi
    ;;
  *)
    echo "Usage: $0 [requestor|technician|both] [apk|appbundle|ipa]" >&2
    exit 1
    ;;
esac

echo "Done."
