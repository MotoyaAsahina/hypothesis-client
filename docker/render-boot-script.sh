#!/bin/sh
#
# Render the client's boot script with this deployment's URLs.
#
# `yarn build` leaves `build/boot-template.js` alongside `build/boot.js`, with
# quoted placeholders such as '__ASSET_ROOT__'. This replaces them with values
# from the environment and writes `build/boot.js`, which is what h's
# CLIENT_URL (via `/hypothesis`) and the client itself load.
#
# Required:
#   H_URL              Public URL of h, e.g. https://h.example.com
#   CLIENT_PUBLIC_URL  Public URL of this container, e.g. https://client.example.com
#
# Optional overrides:
#   ASSET_ROOT, SIDEBAR_APP_URL, NOTEBOOK_APP_URL, PROFILE_APP_URL

set -eu

html_root=/usr/share/nginx/html/hypothesis
version="$(readlink "$html_root/current")"
build_dir="$html_root/$version/build"

: "${H_URL:?H_URL must be set, e.g. https://h.example.com}"
: "${CLIENT_PUBLIC_URL:?CLIENT_PUBLIC_URL must be set, e.g. https://client.example.com}"

h_url="${H_URL%/}"
client_public_url="${CLIENT_PUBLIC_URL%/}"

asset_root="${ASSET_ROOT:-$client_public_url/hypothesis/$version/}"
case "$asset_root" in
  */) ;;
  *) asset_root="$asset_root/" ;;
esac
sidebar_app_url="${SIDEBAR_APP_URL:-$h_url/app.html}"
notebook_app_url="${NOTEBOOK_APP_URL:-$h_url/notebook}"
profile_app_url="${PROFILE_APP_URL:-$h_url/user-profile}"

for value in "$asset_root" "$sidebar_app_url" "$notebook_app_url" "$profile_app_url"; do
  case "$value" in
    *\"*|*\'*)
      echo "$0: URLs must not contain quotes: $value" >&2
      exit 1
      ;;
  esac
done

# Escape characters that are special in a sed replacement using `|` as the
# delimiter.
escape() {
  printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'
}

sed \
  -e "s|['\"]__ASSET_ROOT__['\"]|\"$(escape "$asset_root")\"|g" \
  -e "s|['\"]__SIDEBAR_APP_URL__['\"]|\"$(escape "$sidebar_app_url")\"|g" \
  -e "s|['\"]__NOTEBOOK_APP_URL__['\"]|\"$(escape "$notebook_app_url")\"|g" \
  -e "s|['\"]__PROFILE_APP_URL__['\"]|\"$(escape "$profile_app_url")\"|g" \
  "$build_dir/boot-template.js" > "$build_dir/boot.js"

if grep -qE "['\"]__[A-Z_0-9]+__['\"]" "$build_dir/boot.js"; then
  echo "$0: unknown placeholder left in $build_dir/boot.js" >&2
  exit 1
fi

echo "$0: rendered boot script for client $version (asset root: $asset_root, sidebar: $sidebar_app_url)"
