# arkadas-luatools

Tek satirla LuaTools + 64-bit Steam kurulumu — herkes icin:

```bash
curl -fsSL https://raw.githubusercontent.com/KadirBerkpolat1/arkadas-luatools/v2.0.0/kur-remote.sh | bash
```

## Gereksinimler

- Linux x86_64, **native Steam** (Flatpak/Snap desteklenmez)
- Stack yoksa resmi installer kendi onkosullarini kurar; sudo ister
- 64-bit stack icin glibc >= 2.34 (prebuilt indirilir; altindaysa kaynaktan derlemeye duser)
- Steam Deck / immutable: kurulum tamamlanir; 7z/innoextract/aria2 kurulamazsa
  yalniz uyari verir (onlar yalniz fix indirirken gerekir, sonra elle kurulabilir)

## Ne kuruluyor

1. **Stack yoksa:** paketin icindeki, sha256-pinli resmi `swwayps/luatools-moon` **v2.9**
   installer'i calisir (`resmi-install-v2.9.sh`, sha256 `7120aa1c…`) — slsteam-moon +
   Lumen + LuaTools plugin. Stack zaten varsa bu adim atlanir.
2. **Her durumda:** `apply.sh` — bagimlilik denetimi (kurulamazsa uyari, durmaz),
   Steam kapatma, yedekli payload overlay (`payload/`), 32-bit istemci pin'i
   (moon64'in geri donus yedeji olarak durur).
3. **Otomatik:** [moon64](https://github.com/KadirBerkpolat1/moon64) ile 64-bit
   steamrt64 stack kurulur ve `moon64 on` ile etkinlesir (prebuilt `SLSsteam.so`,
   [slsteam-moon-x64](https://github.com/KadirBerkpolat1/slsteam-moon-x64)
   release'inden, sha256 + pattern gate dogrulamali; netsock64 cert patch
   derleyici varsa derlenir, yoksa kapali kalir). Basarisiz olursa 32-bit stack
   aynen calisir. Atlamak icin `SKIP_MOON64=1`.
4. **Opt-in soru:** CloudRedirect 64-bit (cloud save yonlendirme) derlenip
   kurulsun mu diye sorar; `e` dersen moon64'ün `build-cloudredirect.sh`'i ile
   derler (git+cmake+g++ gerekir, non-fatal kurulmaya calisilir). Default: hayir.
   Sorusuz kurmak icin `CLOUDREDIRECT=1`, hic sormamak icin `SKIP_CLOUDREDIRECT=1`.

Payload = [KadirBerkpolat1/lumen](https://github.com/KadirBerkpolat1/lumen) `main`
agacinin v2.9 uzerine delta'si (FreeTP + online-fix.me fixes menu, FakeAppId swap,
EOS tile) + [KadirBerkpolat1/luatools-moon](https://github.com/KadirBerkpolat1/luatools-moon)
store butonu.

## moon64 makinesinde

`~/.local/share/moon64/moon64` varsa `apply.sh` SLSsteam wrapper'ina,
`environment.d`'ye ve 32-bit pin'lere **dokunmaz** (onlari moon64 yonetir);
yalniz lua agaci guncellenir, moon64 ve CloudRedirect bolumleri atlanir.

## Release sureci

Her surumde: tar'i `arkadas-luatools.tar.gz` olarak yeniden kur (`--exclude=.git
--exclude=kur-remote.sh`), `sha256sum`'i `kur-remote.sh` icindeki `EXPECTED_SHA256`'a
yaz, yeni tag ac, release'e tar + `.sha256` asset'i yukle, README'deki URL'yi yeni
tag'e cevir.

## Lisans

`resmi-install-v2.9.sh` swwayps/luatools-moon v2.9'dan aynen alinmistir; AGPL-3.0
(`LICENSE`). Payload'daki lua dosyalari ayni lisansli projelerin fork'larindan gelir.
