#!/usr/bin/env bash
# Publica el APK release de Toka en un repositorio F-Droid propio.
# Requiere F_DROID_REPO con la ruta al repo (debe tener un script publicar.sh).
# Uso: F_DROID_REPO=/ruta/al/repo scripts/publicar-apk.sh [ruta.apk]   (por defecto, el APK release recién compilado; no compila)
#
# Compila antes con la versión del tag, no con la de desarrollo (versionCode 1, que F-Droid vería como
# más vieja que cualquier release):
#   cd android && ./gradlew assembleRelease -PtokaVersionName=0.3.0 -PtokaVersionCode=300
# versionCode = major*10000 + minor*100 + patch, igual que el workflow de release.
set -euo pipefail
: "${F_DROID_REPO:?export F_DROID_REPO=/ruta/al/repo-fdroid}"
cd "$(dirname "$0")/.."
exec "$F_DROID_REPO/publicar.sh" "$(realpath "${1:-android/app/build/outputs/apk/release/app-release.apk}")"
