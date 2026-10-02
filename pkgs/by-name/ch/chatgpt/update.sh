#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl libxml2 gawk nix nixfmt
# shellcheck shell=bash

set -euo pipefail

BASE_URL="https://persistent.oaistatic.com/codex-app-prod"
SOURCE_NIX="$(dirname "${BASH_SOURCE[0]}")/source.nix"

XML_DATA=$(curl --fail --silent --show-error "$BASE_URL/appcast.xml")
DARWIN_VERSION=$(echo "$XML_DATA" | xmllint --xpath '/rss/channel/item[1]/*[local-name()="shortVersionString"]/text()' -)
DARWIN_URL=$(echo "$XML_DATA" | xmllint --xpath 'string(//item[1]/enclosure/@url)' -)
DARWIN_HASH=$(nix-prefetch-url "$DARWIN_URL" | xargs nix --extra-experimental-features nix-command hash convert --hash-algo sha256 --to sri)

declare -A LINUX_URLS LINUX_HASHES
LINUX_VERSION=""
for arch in amd64 arm64; do
    PACKAGES=$(curl --fail --silent --show-error "$BASE_URL/linux/deb/dists/stable/main/binary-$arch/Packages")
    # Select the ChatGPT stanza rather than assuming it is the only package.
    PACKAGE=$(echo "$PACKAGES" | awk 'BEGIN { RS = "" } /^Package: chatgpt\n/ { print; exit }')
    VERSION=$(echo "$PACKAGE" | awk '/^Version: / { print $2 }')
    FILENAME=$(echo "$PACKAGE" | awk '/^Filename: / { print $2 }')
    SHA256=$(echo "$PACKAGE" | awk '/^SHA256: / { print $2 }')
    if [[ -z "$VERSION" || -z "$FILENAME" || -z "$SHA256" ]]; then
        echo "Missing ChatGPT package metadata for $arch" >&2
        exit 1
    fi
    if [[ -n "$LINUX_VERSION" && "$LINUX_VERSION" != "$VERSION" ]]; then
        echo "Linux package versions differ between architectures" >&2
        exit 1
    fi
    LINUX_VERSION="$VERSION"
    LINUX_URLS[$arch]="$BASE_URL/linux/deb/$FILENAME"
    LINUX_HASHES[$arch]=$(nix --extra-experimental-features nix-command hash convert --hash-algo sha256 --to sri "$SHA256")
done

TEMP_SOURCE=$(mktemp)
trap 'rm -f "$TEMP_SOURCE"' EXIT
cat > "$TEMP_SOURCE" <<EOF
{
  darwin = {
    version = "$DARWIN_VERSION";
    src = {
      url = "$DARWIN_URL";
      hash = "$DARWIN_HASH";
    };
  };
  linux = {
    version = "$LINUX_VERSION";
    src = {
      x86_64-linux = {
        url = "${LINUX_URLS[amd64]}";
        hash = "${LINUX_HASHES[amd64]}";
      };
      aarch64-linux = {
        url = "${LINUX_URLS[arm64]}";
        hash = "${LINUX_HASHES[arm64]}";
      };
    };
  };
}
EOF
nixfmt "$TEMP_SOURCE"
cp "$TEMP_SOURCE" "$SOURCE_NIX"
