# Bevindingen: Chaos Engine Launcher - win32-prefix faalt op WoW64-wine

## Probleem
Op een andere PC (CachyOS/Arch-gebaseerd) faalt de launcher met:
```
wine: WINEARCH is set to 'win32' but this is not supported in wow64 mode.
[game] FOUT: wineboot mislukt (prefix: /home/noa/GAMEPREFIXES/ChaosEngine/pfx)
```

## Oorzaak
- De Chaos Engine game is 32-bit, maar dat maakt een win32-prefix niet nodig.
- Nieuwe Wine (10.8+/11+) is **wow64-only**: de wine-build ondersteunt geen
  win32-prefixes meer en weigert `WINEARCH=win32` hard met bovenstaande fout.
- Het installeren van lib32-pakketten lost dit **niet** op — de weigering zit in
  de wine-build zelf, niet in ontbrekende 32-bit bibliotheken.
- `install_wine32.sh` detecteerde dit voorheen niet en zou ten onrechte een
  lib32-installatie voorstellen.

## Oplossing
Gebruik een **win64-prefix met WoW64**. WoW64 draait de 32-bit exe native
zonder lib32-pakketten. Concreet in `chaosengine.sh`:

```bash
export PREFIX_ARCH="win64"   # was: win32
export SCRIPT_VERSION="2"    # marker-versie → eenmalige re-provision
```

De `PRE_PROVISION_HOOKS=("install_wine32")` is **verwijderd**: een win64-prefix
heeft geen 32-bit Wine nodig. `game-common.sh` laat een 32-bits exe in een
win64-prefix expliciet toe (game-common.sh:212-222) en `_prefix_dir_32()` wijst
in een win64-prefix naar `syswow64` (game-common.sh:271-281).

## install_wine32.sh (hook behouden voor andere games)
De hook blijft bestaan voor games die écht een win32-prefix eisen, maar is
bijgewerkt:

1. **WoW64-detectie**: faalt `WINEARCH=win32 wineboot --help` met de melding
   "... not supported in wow64 mode", dan toont de hook een popup die adviseert
   `PREFIX_ARCH="win64"` te zetten (i.p.v. te proberen lib32 te installeren) en
   stopt met exit 1.
2. **Legacy-fallback**: op systemen met echte 32-bit Wine (bv. Debian met
   `wine32:i386`) blijft de OS-specifieke installatie-popup werken.
3. **Pacman-lijst opgeschoond**: `lib32-libxslt` en `lib32-gst-plugins-base-libs`
   zijn verwijderd (CVE-2026-3099) en `--needed` is toegevoegd.

## Verificatie
Na wijziging:
1. Launcher draait op de doel-PC (CachyOS) zonder de wow64-weigering.
2. Win64-prefix wordt aangemaakt; de 32-bit exe start via WoW64.
3. Geen lib32-pakketten of multilib-repo meer nodig voor deze game.
4. Marker `v2` zorgt dat een bestaande prefix eenmalig opnieuw geprovisiond wordt.

## Uitbreiding (2026-10-09): OS-aware installatie-popup
`install_wine32.sh` toont een GUI-popup (kdialog → zenity → notify-send) in
plaats van alleen terminaltekst. De popup:

- detecteert het OS vooraf (`PRETTY_NAME` uit `/etc/os-release` + pakketbeheerder
  via `_distro_pkg`) en toont de bijbehorende installatie-opdracht;
- biedt **"Installeer nu"** aan dat de installatie via `sudo`/`pkexec` uitvoert
  (zelfde patroon als `install_gamescope.sh`; vrijwillig, geen root-vereiste);
- toont bij Arch/CachyOS eerst de handmatige stap "[multilib] aanzetten in
  /etc/pacman.conf" vóór de pakketopdracht;
- verschijnt ook wanneer de game via `game-gui.py` (GAME_GUI=1) wordt gestart.

Herbruikbare helpers in `game-common.sh`: `_gui_message`, `_gui_confirm`,
`_os_pretty_name`. "Nee"/annuleren stopt provisioning nog steeds met exit 1.

Dit is de **legacy-route**; voor wow64-only builds is de WoW64-popup hierboven
de primaire uitkomst.
