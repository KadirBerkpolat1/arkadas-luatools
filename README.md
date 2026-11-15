# arkadas-luatools

Tek satirla LuaTools (32-bit Steam) kurulumu — herkes icin:

```bash
curl -fsSL https://raw.githubusercontent.com/KadirBerkpolat1/arkadas-luatools/v1.0.1/kur-remote.sh | bash
```

## Gereksinimler

- Linux x86_64, **native Steam** (Flatpak/Snap desteklenmez)
- Stack yoksa resmi installer kendi onkosullarini kurar; sudo ister
- Steam Deck / immutable: kurulum tamamlanir; 7z/innoextract/aria2 kurulamazsa
  yalniz uyari verir (onlar yalniz fix indirirken gerekir, sonra elle kurulabilir)

## Ne kuruluyor

1. **Stack yoksa:** paketin icindeki, sha256-pinli resmi `swwayps/luatools-moon` **v2.9**
   installer'i calisir (`resmi-install-v2.9.sh`, sha256 `7120aa1c…`) — slsteam-moon +
   Lumen + LuaTools plugin. Stack zaten varsa bu adim atlanir.
2. **Her durumda:** `apply.sh` — bagimlilik denetimi (kurulamazsa uyari, durmaz),
   Steam kapatma, yedekli payload overlay (`payload/`), 32-bit istemci pin'i.

Payload = [KadirBerkpolat1/lumen](https://github.com/KadirBerkpolat1/lumen) `main`
agacinin v2.9 uzerine delta'si (FreeTP + online-fix.me fixes menu, FakeAppId swap,
EOS tile) + [KadirBerkpolat1/luatools-moon](https://github.com/KadirBerkpolat1/luatools-moon)
store butonu.

## moon64 makinesinde

`~/.local/share/moon64/moon64` varsa `apply.sh` SLSsteam wrapper'ina,
`environment.d`'ye ve 32-bit pin'lere **dokunmaz** (onlari moon64 yonetir);
yalniz lua agaci guncellenir.

## Release sureci

Her surumde: tar'i `arkadas-luatools.tar.gz` olarak yeniden kur (`--exclude=.git
--exclude=kur-remote.sh`), `sha256sum`'i `kur-remote.sh` icindeki `EXPECTED_SHA256`'a
yaz, yeni tag ac, release'e tar + `.sha256` asset'i yukle, README'deki URL'yi yeni
tag'e cevir.

## Lisans

`resmi-install-v2.9.sh` swwayps/luatools-moon v2.9'dan aynen alinmistir; AGPL-3.0
(`LICENSE`). Payload'daki lua dosyalari ayni lisansli projelerin fork'larindan gelir.
