#!/usr/bin/env bash
# Berk's LuaTools setup on top of the official swwayps/luatools-moon v2.9 install:
# Steam pinned to 32-bit ubuntu12_32, FreeTP + online-fix.me fixes menu,
# store header button fix, 32-bit libcrypto.so.1.1 for SLSsteam's SHA-1.
# Run as the desktop user (not root) after install.sh has finished.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PAYLOAD="$HERE/payload"
LUMEN="$HOME/.local/share/Lumen"
SLS="$HOME/.local/share/SLSsteam"

[ "$(id -u)" -ne 0 ] || { echo "root olarak calistirma; kendi kullanicinla calistir" >&2; exit 1; }
for f in "$LUMEN/lumen" "$SLS/SLSsteam.so" "$SLS/path/steam"; do
	[ -e "$f" ] || { echo "eksik: $f (once resmi install.sh)" >&2; exit 1; }
done
if ! grep -q '"tag": "v2.9"' "$LUMEN/versions.json" 2>/dev/null; then
	echo "uyari: kurulu surum v2.9 degil; yamalar v2.9 icin hazirlandi" >&2
fi

# moon64 makinesinde SLSsteam wrapper'ini, environment.d pin'ini ve 32-bit
# isaret dosyalarini moon64 yonetir (path/steam orada 64-bit wrapper'dir).
# Bu paket orada yalniz lua agacini gunceller; makine sahibi dosyalara dokunmaz.
MOON_OWNED=0
if [ -x "$HOME/.local/share/moon64/moon64" ]; then
	MOON_OWNED=1
	echo "moon64 algilandi: SLSsteam wrapper'i, environment.d ve 32-bit pin'ler moon64'te; yalniz lua agaci guncelleniyor"
fi

if [ "${SKIP_DEPS:-0}" != 1 ]; then
	if command -v pacman >/dev/null; then
		sudo pacman -S --needed --noconfirm 7zip innoextract aria2
	elif command -v apt-get >/dev/null; then
		sudo apt-get install -y 7zip innoextract aria2 || sudo apt-get install -y p7zip-full innoextract aria2
	elif command -v dnf >/dev/null; then
		sudo dnf install -y 7zip innoextract aria2 || sudo dnf install -y p7zip p7zip-plugins innoextract aria2
	elif command -v zypper >/dev/null; then
		sudo zypper --non-interactive install 7zip innoextract aria2
	else
		echo "uyari: paket yoneticisi taninmadi; 7z, innoextract, aria2 elle kurulmali" >&2
	fi
fi

if [ "${SKIP_STOP:-0}" != 1 ]; then
	pid="$(cat "$HOME/.steam/steam.pid" 2>/dev/null || true)"
	if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
		echo "Steam kapatiliyor..."
		"$SLS/path/steam" -shutdown >/dev/null 2>&1 || true
		for _ in $(seq 30); do kill -0 "$pid" 2>/dev/null || break; sleep 1; done
	fi
	pkill -f "$LUMEN/lumen" 2>/dev/null || true
fi

BACKUP="$HOME/.local/share/arkadas-luatools-yedek-$(date +%Y%m%d-%H%M%S)"
while IFS= read -r -d '' src; do
	rel="${src#"$PAYLOAD"/}"
	dst="$HOME/$rel"
	if [ "$MOON_OWNED" = 1 ]; then
		case "$rel" in
			.local/share/SLSsteam/path/steam|.config/environment.d/steam-32bit.conf)
				echo "atlaniyor (moon64 yonetir): ~/$rel"
				continue
				;;
		esac
	fi
	if [ -e "$dst" ]; then
		mkdir -p "$BACKUP/$(dirname "$rel")"
		cp -a "$dst" "$BACKUP/$rel"
	fi
	mkdir -p "$(dirname "$dst")"
	install -m "$(stat -c %a "$src")" "$src" "$dst"
	echo "kuruldu: ~/$rel"
done < <(find "$PAYLOAD" -type f -print0)

if [ "$MOON_OWNED" != 1 ]; then
	for r in "$HOME/.steam/steam" "$HOME/.local/share/Steam" "$HOME/.steam/debian-installation"; do
		[ -d "$r" ] && : > "$r/.steam-disable-steamrt64-client"
	done
fi

[ -d "$BACKUP" ] && echo "eski dosyalar: $BACKUP"
echo "tamam. Steam'i normal kisayoldan ac (ilk acilista 32-bit istemciye geri iner)."
