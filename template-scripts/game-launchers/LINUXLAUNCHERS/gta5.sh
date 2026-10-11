#!/bin/bash
# GTA V (Build 2802, Online, Goldberg Emu) — Proton launcher via game-common.sh
# Let op: deze repack gebruikt Goldberg Steam emulator → GEEN gamescope!

set -euo pipefail

# --- Basisinstellingen (ALLE exports VOOR sourcing game-common.sh) ---
export GAME_NAME="GTA5"
export GAME_DIR="/mnt/VG_00/PUBLIC-LIBRARY/GAMES/GAMES/WINDOWS/GTA V Build 2802-Online 1_64 met alle DLC_s - Werkt OK"
export GAME_EXE="$GAME_DIR/GTA5.exe"
export PREFIX_ARCH="win64"
export SCRIPT_VERSION="1"
export CREATE_DESKTOP_SHORTCUT="1"
export GAME_DISPLAY_NAME="GTA V"
export GAME_ICON="gta5.png"

export GAME_LAUNCHER="$(readlink -f "$0")"

# --- Proton / Wine configuratie ---
export PROTON_ENABLED="1"
export PROTON_PIN="GE-Proton11-7"
export STEAM_APPID="271590"              # GTA V Steam appid (voor ProtonFixes + Goldberg)

# VC++ 2019 runtime via winetricks (geen _CommonRedist in deze game-map)
export VC_RUNTIME_METHOD="winetricks"

# DirectX 11 via DXVK (in GE-Proton ingebouwd)
export DXVK_HUD="fps,msgs"
export VKD3D_SHADER_CACHE_SIZE="4"
export WINEDEBUG="-all"

# ── MOD-STAND (24-09-2026): NIET her-activeren zonder .NET-runtime ──────────
# De game crashed met "FATAL UNHANDLED EXCEPTION" in ScriptHookVDotNet2
# (GTA.ScriptDomain.LoadAssembly) bij het laden van oude .NET-mod .dll's,
# want deze prefix heeft géén .NET Framework geïnstalleerd. Daarom uit (.off):
#   scripts/ATMBankHeist.dll            (2017 → InvalidCastException)
#   scripts/NativeUI.dll                (2019 → NullReferenceException)
#   ScriptHookVDotNet.asi + ScriptHookVDotNet2.dll
# Native/ASI-mods (Enhanced Native Trainer, LeFixSpeedo, OpenInteriors,
# The Red House, CustomCameraVPlus) en Lua-mods (LuaPlugin_ForUsers) werken.
# Terugbrengen: eerst .NET installeren (bv. winetricks dotnet48), dan de
# .off-bestanden hernoemen en testen via een echte game-run.
# ReShade 6.8.0-payload in dxgi.dll (rollback: Backup/reshade_5.9.2_*).

# ── LOGS: staan in $GAME_DIR, NIET in de prefix ──────────────────────────
# De "some shaders have error"-melding verwijst naar ReShade.log.
#   ReShade.log              → ReShade 6.8.0 (via dxgi.dll); de shader-melding
#   ScriptHookV.log          → ScriptHookV; registreert élke .asi-plugin
#   OpenIV.log               → OpenIV.asi (groot, pure trace)
#   asiloader.log            → geladen *.asi-lijst
#   LeFixSpeedo/LeFixSpeedo.log, openCameraV.log, HeapAdjuster.log
#   ScriptHookVDotNet2.log   → .NET-hook; staat UIT (ScriptHookVDotNet2.dll.off)
# Prefix: ~/GAMEPREFIXES/GTA5/pfx/winetricks.log (schreef tot nu toe niets).
# LET OP: ReShade herover-schrijft ReShade.log bij elke start. Een log van een
# vorige sessie is na een nieuwe start weg — kopiëren als je hem wilt bewaren.

# ── ReShade-config in $GAME_DIR/ReShade.ini (bewezen 2026-09-27) ─────────
# SkipLoadingDisabledEffects=1   (was 0)
#   Omdat het 0 was, compileerde ReShade álle 274 shaders in
#   reshade-shaders/ in plaats van alleen de actieve technieken. Gevolg:
#   de "some shaders have error"-melding (30 mislukte shaders) én 84 minuten
#   compileertijd bij een koude cache.
#   Gemeten na de fix: 0 compile-fouten, 7 shaders, 30 seconden.
# IntermediateCachePath=C:\Users\peter\AppData\Local\Temp\ReShade
#   (was C:\Users\Admin\... — die user bestaat niet in deze prefix; de users
#   zijn peter, Public en steamuser).
# Backup: $GAME_DIR/Backup/ReShade.ini.6.8.0_preskipdisabled_*.bak
# Let op: de game her-schrijft ReShade.ini bij exit NIET (geverifieerd
# 2026-09-27) en AutoSavePreset=0. Handmatig wijzigen blijft dus ook staan.

# ── GEBRUIKERS-KEUZES: bestaan al, de launcher raakt ze niet aan ──────────
# 1. Grafische kwaliteit → het eigen menu van het spel:
#    Escape → Settings → Graphics. Resolutie, MSAA, FXAA, TXAA, SSAO, PostFX,
#    schaduwkwaliteit. Het spel schrijft die zelf weg naar
#    ~/GAMEPREFIXES/GTA5/pfx/drive_c/users/steamuser/Documents/Rockstar Games/
#    GTA V/settings.xml. De launcher leest of overschrijft dat bestand niet.
#    Let op bij "noisy": staat daar ScreenWidth/Height nog op 800/600, dan
#    wordt het beeld opgeschaald naar de monitor. Dat maakt scherpen ruisig.
# 2. Shader → het eigen menu van ReShade: HOME-toets (ReShade.ini
#    KeyOverlay=36) → Home-tab → preset-kiezer. In $GAME_DIR/Reshade-settings/
#    liggen 8 presets (A t/m H); actief is "B - Custom.ini". Live wisselen mag:
#    het spel schrijft de preset-keuze niet terug (AutoSavePreset=0), dus een
#    gebruiker die experimenteert verandert niets voor de volgende.
#    De effecten staan in de Home-tab per shader aangevinkt en kunnen daar
#    individueel aan/uit worden gezet.

# ── SHADERS: 7 actief, en dat is de gebruiker zijn keuze (2026-09-27) ──────
# De actieve preset ("B - Custom.ini") noemt 4 technieken, maar ReShade
# zet er 7 aan — alle 7 staan bij de eerste start aangevinkt:
#   CAS.fx                    Shaders\
#   CAS.fx                    Shaders\SweetFX\
#   DPX.fx                    Shaders\
#   DPX.fx                    Shaders\SweetFX\
#   FilmicAnamorphSharpen.fx  Shaders\
#   FilmicAnamorphSharpen.fx  Shaders\Fubax\
#   AdaptiveTonemapper.fx     Shaders\FXShaders\
# Oorzaak: EffectSearchPaths=.\reshade-shaders\Shaders\** is recursief,
# terwijl de preset alleen de bestandsnaam noemt — "CAS.fx" matcht daardoor
# twee bestanden, en ReShade vinkt beide aan. Elke scherper draait dus 2x.
# WAT DE GEBRUIKER DOET: niets. Bij de eerste start staan alle 7 aangevinkt
# en in de ReShade Home-tab (HOME-toets) kan per shader een vinkje weg.
# Dat is de bedoelde plek; daarom wordt hier en in de ini-files niets
# aangepast — ook niet de waarden (CAS Sharpening 1.0, DPX Saturation
# 3.26, FilmicAnamorphSharpen Strength 50), die liggen binnen de bereiken
# die de shader-auteurs zelf hebben gezet.

# GEEN gamescope! → conflicteert met Goldberg Steam emulator (Steam API init)
# export GAME_GAMESCOPE="1"

# --- Provision hooks (bij eerste run: prefix setup) ---
# install_vcrun2019: VC++ 2019 runtime (noodzakelijk voor GTA V)
PROVISION_HOOKS=("install_vcrun2019")

# Pre-launch hooks (bij ELKE start vóór game launch)
# disable_winebus: zet winebus Enable SDL=0 (hidraw aan) → toetsenbord werkt
PRE_LAUNCH_HOOKS=("disable_winebus")

# --- Core laden EN pas daarna game_main aanroepen ---
source "$(dirname "$(readlink -f "$0")")/../../game-core/game-common.sh"

# Start de game
game_main "$@"