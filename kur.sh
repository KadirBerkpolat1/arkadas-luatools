#!/usr/bin/env bash
# Tek komutluk kurulum: resmi luatools-moon v2.9 stack + Berk'in payload'i.
#
#   ./kur.sh
#
# 1. Stack yoksa (ilk kurulum) paketin icindeki, sha256'si dogrulanmis resmi
#    v2.9 installer calisir (slsteam-moon + Lumen + LuaTools plugin; kendi
#    sorularini sorar — CloudRedirect vb., oldugu gibi birakabilirsin).
# 2. Stack zaten varsa o adim atlanir (guncelleme modu).
# 3. Sonra apply.sh: payload overlay + 32-bit pin + yedek.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
RESMI="$HERE/resmi-install-v2.9.sh"
RESMI_SHA256="7120aa1c402aca9071f13525ee75adf2ffb8012d519f9bafcedba5485b3f7a47"
LUMEN="$HOME/.local/share/Lumen"
SLS="$HOME/.local/share/SLSsteam"

[ "$(id -u)" -ne 0 ] || { echo "root olarak calistirma; kendi kullanicinla calistir" >&2; exit 1; }

if [ -e "$LUMEN/lumen" ] && [ -e "$SLS/SLSsteam.so" ] && [ -e "$SLS/path/steam" ]; then
	echo "stack zaten kurulu; resmi installer atlaniyor (guncelleme modu)"
else
	[ -f "$RESMI" ] || { echo "eksik: $RESMI" >&2; exit 1; }
	got="$(sha256sum "$RESMI" | cut -d' ' -f1)"
	[ "$got" = "$RESMI_SHA256" ] || { echo "resmi installer bozuk: sha256 $got != $RESMI_SHA256" >&2; exit 1; }
	echo "== resmi luatools-moon v2.9 kurulumu =="
	bash "$RESMI"
fi

echo
echo "== Berk'in yamalari (payload + 32-bit pin) =="
exec "$HERE/apply.sh"
