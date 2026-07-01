#!/bin/bash
# IyziPanel — derle, .app paketle, ikon üret ve imzala.
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="IyziPanel"
BUNDLE_ID="tr.com.singleton.mac.iyzipanel"
APP_DIR="build/${APP_NAME}.app"
# Masterteck (Apple Distribution) imza kimliği. Farklı kimlik için: SIGN_ID=... ./build.sh
SIGN_ID="${SIGN_ID:-FBEC9AAAA91BCF73D5B36B46ED8672303994A8BE}"

echo "▸ Swift release derleniyor…"
swift build -c release

echo "▸ Uygulama ikonu üretiliyor…"
rm -rf build/IyziPanel.iconset
swift scripts/generate_icon.swift build/IyziPanel.iconset >/dev/null
iconutil -c icns build/IyziPanel.iconset -o build/AppIcon.icns

echo "▸ .app paketleniyor…"
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"
cp ".build/release/${APP_NAME}" "${APP_DIR}/Contents/MacOS/${APP_NAME}"
cp Info.plist "${APP_DIR}/Contents/Info.plist"
cp build/AppIcon.icns "${APP_DIR}/Contents/Resources/AppIcon.icns"

echo "▸ İmzalanıyor (${SIGN_ID})…"
codesign --force --deep --options runtime \
    --identifier "${BUNDLE_ID}" \
    --sign "${SIGN_ID}" \
    "${APP_DIR}"

echo "▸ İmza doğrulanıyor…"
codesign --verify --verbose "${APP_DIR}"

echo "✓ Hazır: ${APP_DIR}"
