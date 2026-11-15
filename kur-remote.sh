#!/usr/bin/env bash
# arkadas-luatools — tek satirlik kurulum:
#   curl -fsSL https://raw.githubusercontent.com/KadirBerkpolat1/arkadas-luatools/main/kur-remote.sh | bash
# Paket release'den iner ve release'deki .sha256 dosyasiyla dogrulanir.
set -euo pipefail
BASE="https://github.com/KadirBerkpolat1/arkadas-luatools/releases/latest/download"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
echo "== arkadas-luatools indiriliyor =="
curl -fsSL "$BASE/arkadas-luatools.tar.gz" -o "$tmp/arkadas-luatools.tar.gz"
curl -fsSL "$BASE/arkadas-luatools.tar.gz.sha256" -o "$tmp/arkadas-luatools.tar.gz.sha256"
(cd "$tmp" && sha256sum -c arkadas-luatools.tar.gz.sha256)
tar -xzf "$tmp/arkadas-luatools.tar.gz" -C "$tmp"
"$tmp/arkadas-luatools/kur.sh"
