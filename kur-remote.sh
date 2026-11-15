#!/usr/bin/env bash
# arkadas-luatools — tek satirlik kurulum:
#   curl -fsSL https://raw.githubusercontent.com/KadirBerkpolat1/arkadas-luatools/v2.0.0/kur-remote.sh | bash
# Paket release'den iner ve bu script'e pinli sha256 ile dogrulanir
# (CDN'in iki asset'i farkli tazelikte sunma yarisi olmaz). Her release'de
# EXPECTED_SHA256 tar ile birlikte guncellenir; release'deki .sha256 asset'i
# ayrica manuel dogrulama icin durur.
set -euo pipefail
BASE="https://github.com/KadirBerkpolat1/arkadas-luatools/releases/download/v2.0.0"
EXPECTED_SHA256="b3a80ec701b3b25412c3d8fc0850fc641abddf49bb3ceda3186ae9d04b840c8f"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
echo "== arkadas-luatools indiriliyor =="
curl -fsSL "$BASE/arkadas-luatools.tar.gz" -o "$tmp/arkadas-luatools.tar.gz"
echo "$EXPECTED_SHA256  $tmp/arkadas-luatools.tar.gz" | sha256sum -c -
tar -xzf "$tmp/arkadas-luatools.tar.gz" -C "$tmp"
"$tmp/arkadas-luatools/kur.sh"
