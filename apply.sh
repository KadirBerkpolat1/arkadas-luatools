#!/usr/bin/env bash
# Berk's LuaTools setup on top of the official swwayps/luatools-moon v2.9 install:
# FreeTP + online-fix.me fixes menu, store header button fix, 32-bit
# libcrypto.so.1.1 for SLSsteam's SHA-1 — sonra moon64 ile 64-bit steamrt64
# stack (32-bit kurulum moon64 off icin yedek olarak durur) ve istege bagli
# CloudRedirect 64-bit derlemesi.
# Run as the desktop user (not root) after install.sh has finished.
# Atlamak icin: SKIP_MOON64=1, SKIP_CLOUDREDIRECT=1 (CLOUDREDIRECT=1 soru sormadan kurar).
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

# 7z / innoextract / aria2 yalniz fix INDIRME aninda kullanilir; kurulumun
# kendisi bunlarsiz da tamamlanir. SteamOS/immutable'da pacman var ama kok
# salt-okunur, sudo parolasiz olabilir: kurulumu asla burada kesme, uyar ve
# devam et — eksik arac gerektiren fix akisi kendi hatasini verir.
if [ "${SKIP_DEPS:-0}" != 1 ]; then
	missing=()
	{ command -v 7z >/dev/null 2>&1 || command -v 7za >/dev/null 2>&1; } || missing+=(7zip)
	command -v innoextract >/dev/null 2>&1 || missing+=(innoextract)
	command -v aria2c >/dev/null 2>&1 || missing+=(aria2)
	if [ "${#missing[@]}" -eq 0 ]; then
		echo "bagimliliklar tamam (7z, innoextract, aria2)"
	else
		echo "eksik bagimliliklar kuruluyor: ${missing[*]}"
		dep_ok=0
		if command -v pacman >/dev/null; then
			if sudo pacman -S --needed --noconfirm "${missing[@]}"; then dep_ok=1; fi
		elif command -v apt-get >/dev/null; then
			if { sudo apt-get update -qq; sudo apt-get install -y "${missing[@]}"; } \
				|| sudo apt-get install -y p7zip-full innoextract aria2; then dep_ok=1; fi
		elif command -v dnf >/dev/null; then
			if sudo dnf install -y "${missing[@]}" \
				|| sudo dnf install -y p7zip p7zip-plugins innoextract aria2; then dep_ok=1; fi
		elif command -v zypper >/dev/null; then
			if sudo zypper --non-interactive install "${missing[@]}"; then dep_ok=1; fi
		fi
		if [ "$dep_ok" != 1 ]; then
			echo "UYARI: kurulamadi (${missing[*]}); kurulum devam ediyor." >&2
			echo "  fix indirmeleri icin sonra elle kur: 7zip (p7zip), innoextract, aria2" >&2
		fi
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

# --- 64-bit steamrt64 stack (moon64, otomatik) -------------------------------
# 32-bit kurulum yedek olarak kalir; moon64 iki mod arasinda gecis yapar
# (moon64 on/off). Kurulum basarisiz olursa 32-bit stack aynen calisir.
moon_ok=0
if [ "$MOON_OWNED" != 1 ] && [ "${SKIP_MOON64:-0}" != 1 ]; then
	echo
	echo "== 64-bit steamrt64 stack (moon64) =="
	# netsock64 cert patch kurulumda derleyiciyle derlenir; derleyici yoksa
	# patch kapali kalir (P2P join haric her sey calisir). Non-fatal kurmaya
	# calis: SteamOS/immutable'da basarisiz olur, sorun degil.
	if ! command -v gcc >/dev/null 2>&1 || ! command -v make >/dev/null 2>&1; then
		echo "cert patch icin derleyici kuruluyor (gcc, make)..."
		if command -v pacman >/dev/null; then sudo pacman -S --needed --noconfirm gcc make || true
		elif command -v apt-get >/dev/null; then { sudo apt-get update -qq && sudo apt-get install -y gcc make; } || true
		elif command -v dnf >/dev/null; then sudo dnf install -y gcc make || true
		elif command -v zypper >/dev/null; then sudo zypper --non-interactive install gcc make || true
		fi
	fi
	tmp_get="$(mktemp)"
	if curl -fsSL --connect-timeout 15 --max-time 300 -o "$tmp_get" \
		"https://raw.githubusercontent.com/KadirBerkpolat1/moon64/main/get.sh" \
		&& bash "$tmp_get"; then
		moon_ok=1
	else
		echo "UYARI: moon64 kurulamadi; 32-bit kurulum calismaya devam ediyor" >&2
		echo "  sonra elle: curl -fsSL https://raw.githubusercontent.com/KadirBerkpolat1/moon64/main/get.sh | bash" >&2
	fi
	rm -f "$tmp_get"
	if [ "$moon_ok" = 1 ]; then
		if "$HOME/.local/share/moon64/moon64" on; then
			echo "moon64 on: 64-bit istemci etkin (32-bit'e donmek icin: moon64 off)"
		else
			echo "UYARI: moon64 on basarisiz; 32-bit kurulum hala calisir" >&2
		fi
	fi
fi

# --- CloudRedirect 64-bit (opt-in) -------------------------------------------
if [ "$moon_ok" = 1 ] && [ "${SKIP_CLOUDREDIRECT:-0}" != 1 ]; then
	want_cr=0
	case "${CLOUDREDIRECT:-}" in 1|e|E|evet|Evet) want_cr=1 ;; esac
	if [ "$want_cr" != 1 ] && [ -r /dev/tty ]; then
		printf 'CloudRedirect (cloud save yonlendirme, 64-bit) derlenip kurulsun mu? [e/H] ' >/dev/tty
		read -r cr_ans </dev/tty || true
		case "${cr_ans:-}" in e|E|y|Y|evet|Evet) want_cr=1 ;; esac
	fi
	if [ "$want_cr" = 1 ]; then
		cr_missing=()
		for t in git cmake g++ file readelf; do command -v "$t" >/dev/null 2>&1 || cr_missing+=("$t"); done
		if [ "${#cr_missing[@]}" -gt 0 ]; then
			echo "CloudRedirect derleme araclari kuruluyor: ${cr_missing[*]}"
			if command -v pacman >/dev/null; then sudo pacman -S --needed --noconfirm git cmake gcc binutils file || true
			elif command -v apt-get >/dev/null; then { sudo apt-get update -qq && sudo apt-get install -y git cmake g++ binutils file; } || true
			elif command -v dnf >/dev/null; then sudo dnf install -y git cmake gcc-c++ binutils file || true
			elif command -v zypper >/dev/null; then sudo zypper --non-interactive install git cmake gcc-c++ binutils file || true
			fi
		fi
		tmp_cr="$(mktemp)"
		if curl -fsSL --connect-timeout 15 --max-time 120 -o "$tmp_cr" \
			"https://raw.githubusercontent.com/KadirBerkpolat1/moon64/main/bin/build-cloudredirect.sh" \
			&& bash "$tmp_cr" --install; then
			echo "CloudRedirect 64-bit kuruldu (~/.local/share/CloudRedirect)"
		else
			echo "UYARI: CloudRedirect kurulamadi; sonra elle kurulabilir (moon64 reposundaki bin/build-cloudredirect.sh --install)" >&2
		fi
		rm -f "$tmp_cr"
	fi
fi

if [ "$moon_ok" = 1 ]; then
	echo "tamam. Steam'i normal kisayoldan ac; 64-bit istemci acilir (dogrulamak icin: moon64 status)."
else
	echo "tamam. Steam'i normal kisayoldan ac (ilk acilista 32-bit istemciye geri iner)."
fi
