#!/usr/bin/env python3
"""
setup_icons.py — Valideer en creëer de vereiste icon-mapstructuur voor game-gui.py en game-gui-fork.py.

Gebruik:
    python3 template-scripts/tools/setup_icons.py [--target DIR] [--yes] [--dry-run] [--check-only]

Doel: Zorgen dat de mapstructuur bestaat die de scrollers verwachten (nieuwe platte structuur):
  - <target>/                 (hoofd-iconen, back.jpg, game-covers)
  - <target>/systems/         (systeem-iconen: ps2.png, n64.png, etc.) — NavNode kijkt HIER EERST
  - <target>/emu-gameicons/   (emu-covers, exact match op display_name) — EmuGame
  - <target>/LINUXLAUNCHERS/  (native launcher scripts)
  - <target>/EMU-LAUNCHERS/   (emu-install.sh, emu-launch.sh, emulation.conf)

Standaard target: /mnt/VG_00/PUBLIC-LIBRARY/PICTURES/ICONS/GAMEICONS/
"""

import sys
import argparse
from pathlib import Path

# Constants matching game-gui-fork.py / game-gui.py
TEMPLATE_ROOT = Path("/mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINEPREFIX/template-scripts")
LAUNCHERS_DIR = TEMPLATE_ROOT / "game-launchers"

# Nieuwe standaard icon-root (platte structuur)
ICONS_ROOT_DEFAULT = Path("/mnt/VG_00/PUBLIC-LIBRARY/PICTURES/ICONS/GAMEICONS")

REQUIRED_DIRS = {
    "gameicons (root)": ICONS_ROOT_DEFAULT,
    "systems": ICONS_ROOT_DEFAULT / "systems",
    "emu-gameicons": ICONS_ROOT_DEFAULT / "emu-gameicons",
    "LINUXLAUNCHERS": ICONS_ROOT_DEFAULT / "LINUXLAUNCHERS",
    "EMU-LAUNCHERS": ICONS_ROOT_DEFAULT / "EMU-LAUNCHERS",
}

# Expected system icons
EXPECTED_SYSTEM_ICONS = {
    "3ds.png", "amiga.png", "atari2600.png", "atarilynx.png", "atari.png",
    "c128.png", "c64.png", "commodore.png", "gba.png", "gb.png",
    "konami.png", "linux.png", "mame.png", "mastersystem.png", "megadrive.png",
    "n64.png", "nds.png", "neogeo.png", "nes.png", "nintendo.png",
    "ps2.png", "ps3.png", "psp.png", "psx.png", "sega.png",
    "snes.png", "sony.png", "turbogrfx.png", "vic20.png", "wii.png", "xbox.png",
}

# Source for system icons (if user wants to populate)
PICTURES_SYSTEMS = Path("/mnt/VG_00/PUBLIC-LIBRARY/PICTURES/ICONS/GAMEICONS/systems")


def _norm(s: str) -> str:
    """Normaliseer voor icon-matching (zoals in game-gui-fork.py)."""
    return "".join(c.lower() for c in s if c.isalnum())


def check_structure(target: Path, verbose: bool = True) -> dict:
    """Controleer de mapstructuur, retourneer dict met status per map."""
    results = {}
    for name, path in REQUIRED_DIRS.items():
        exists = path.exists() and path.is_dir()
        file_count = len(list(path.iterdir())) if exists else 0
        results[name] = {"path": path, "exists": exists, "count": file_count}
        if verbose:
            status = "✓" if exists else "✗"
            extra = f" ({file_count} items)" if exists else " — ONTBREEKT"
            print(f"  {status} {name:<20} → {path}{extra}")
    return results


def check_system_icons(verbose: bool = True) -> dict:
    """Controleer welke systeem-iconen aanwezig/ontbreken."""
    systems_dir = REQUIRED_DIRS["systems"]
    if not systems_dir.exists():
        return {"missing": set(EXPECTED_SYSTEM_ICONS), "present": set(), "extra": set()}

    present = {f.name for f in systems_dir.iterdir() if f.is_file()}
    missing = EXPECTED_SYSTEM_ICONS - present
    extra = present - EXPECTED_SYSTEM_ICONS

    if verbose:
        print(f"\n  Systeem-iconen in {systems_dir}:")
        print(f"    Aanwezig: {len(present)}/{len(EXPECTED_SYSTEM_ICONS)}")
        if missing:
            print(f"    Ontbrekend ({len(missing)}): {', '.join(sorted(missing))}")
        if extra:
            print(f"    Extra ({len(extra)}): {', '.join(sorted(extra))}")
    return {"missing": missing, "present": present, "extra": extra}


def check_back_jpg(verbose: bool = True) -> bool:
    """Controleer of back.jpg bestaat in root."""
    back_path = REQUIRED_DIRS["gameicons (root)"] / "back.jpg"
    exists = back_path.exists() and back_path.is_file()
    if verbose:
        status = "✓" if exists else "✗"
        print(f"  {status} back.jpg           → {back_path}")
    return exists


def check_emu_gameicons(verbose: bool = True) -> int:
    """Tel emu-gameicons."""
    emu_dir = REQUIRED_DIRS["emu-gameicons"]
    if not emu_dir.exists():
        if verbose:
            print(f"  ✗ emu-gameicons      → {emu_dir} (ONTBREEKT)")
        return 0
    count = len([f for f in emu_dir.iterdir() if f.is_file()])
    if verbose:
        print(f"  ✓ emu-gameicons      → {emu_dir} ({count} covers)")
    return count


def create_missing_dirs(dry_run: bool = False) -> list:
    """Creëer ontbrekende mappen."""
    created = []
    for name, path in REQUIRED_DIRS.items():
        if not path.exists():
            if dry_run:
                print(f"  [dry-run] mkdir -p {path}")
            else:
                path.mkdir(parents=True, exist_ok=True)
                print(f"  ✓ Aangemaakt: {path}")
            created.append(path)
    return created


def populate_system_icons(source: Path, target: Path, dry_run: bool = False) -> int:
    """Kopieer/symlink systeem-iconen van bron naar target."""
    if not source.exists():
        print(f"  Bronmap niet gevonden: {source}")
        return 0

    copied = 0
    for icon in EXPECTED_SYSTEM_ICONS:
        src = source / icon
        dst = target / icon
        if src.exists() and not dst.exists():
            if dry_run:
                print(f"  [dry-run] cp {src} {dst}")
            else:
                import shutil
                shutil.copy2(src, dst)
                print(f"  ✓ Gekopieerd: {icon}")
            copied += 1
    return copied


def verify_icon_resolution():
    """Test de _resolve_icon logica tegen de daadwerkelijke bestanden."""
    print("\n  Icon-resolutie test:")
    # NavNode logic: systems/ first, then root (gameicons)
    systems_dir = REQUIRED_DIRS["systems"]
    gameicons_dir = REQUIRED_DIRS["gameicons (root)"]

    norm_icons = {}
    for d in [systems_dir, gameicons_dir]:
        if d.exists():
            for f in d.iterdir():
                if f.is_file() and _norm(f.stem) not in norm_icons:
                    norm_icons[_norm(f.stem)] = f

    print(f"    Totaal unieke iconen (genormaliseerd): {len(norm_icons)}")

    # Test a few known systems
    test_systems = ["ps2", "n64", "snes", "linux", "windows", "steam"]
    for sys in test_systems:
        n = _norm(sys)
        if n in norm_icons:
            print(f"    ✓ '{sys}' → {norm_icons[n].name}")
        else:
            print(f"    ✗ '{sys}' → NIET GEVONDEN")

    # Test back.jpg
    back_norm = _norm("back")
    if back_norm in norm_icons:
        print(f"    ✓ 'back' → {norm_icons[back_norm].name}")
    else:
        print(f"    ✗ 'back' → NIET GEVONDEN")


def main():
    parser = argparse.ArgumentParser(
        description="Valideer en creëer icon-mapstructuur voor game-gui(.fork).py",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Voorbeelden:
  python3 template-scripts/tools/setup_icons.py                    # Interactief
  python3 template-scripts/tools/setup_icons.py --yes              # Auto-ja, maak mappen aan
  python3 template-scripts/tools/setup_icons.py --dry-run          # Alleen tonen wat zou gebeuren
  python3 template-scripts/tools/setup_icons.py --check-only       # Alleen controleren, niets wijzigen
  python3 template-scripts/tools/setup_icons.py --populate-systems # Ook systeem-iconen vullen vanuit PICTURES
        """
    )
    parser.add_argument("--target", type=Path, default=ICONS_ROOT_DEFAULT,
                        help="Basis-map (default: /mnt/VG_00/PUBLIC-LIBRARY/PICTURES/ICONS/GAMEICONS/)")
    parser.add_argument("--yes", "-y", action="store_true",
                        help="Niet vragen, direct mappen aanmaken")
    parser.add_argument("--dry-run", action="store_true",
                        help="Alleen tonen wat zou gebeuren, niets wijzigen")
    parser.add_argument("--check-only", action="store_true",
                        help="Alleen controleren, niets aanmaken/vragen")
    parser.add_argument("--populate-systems", action="store_true",
                        help="Ook ontbrekende systeem-iconen kopiëren van PICTURES/ICONS/GAMEICONS/systems/")
    parser.add_argument("--verify", action="store_true",
                        help="Test icon-resolutie logica (NavNode/Game/EmuGame)")

    args = parser.parse_args()

    # Update paths if custom target
    if args.target != ICONS_ROOT_DEFAULT:
        for name in REQUIRED_DIRS:
            rel = REQUIRED_DIRS[name].relative_to(ICONS_ROOT_DEFAULT)
            REQUIRED_DIRS[name] = args.target / rel

    print(f"\n=== Icon-mapstructuur validatie ===")
    print(f"Basis: {args.target}\n")

    # 1. Check structure
    print("Mapstructuur:")
    results = check_structure(args.target)

    # 2. Check specific files
    print("\nKritieke bestanden:")
    check_back_jpg()
    check_emu_gameicons()
    check_system_icons()

    # 3. Verify resolution logic if requested
    if args.verify:
        verify_icon_resolution()

    # 4. Handle missing dirs
    missing_dirs = [name for name, r in results.items() if not r["exists"]]
    if missing_dirs:
        print(f"\nOntbrekende mappen: {', '.join(missing_dirs)}")
        if args.check_only:
            print("  (--check-only: niets gewijzigd)")
            return 1
        if args.dry_run:
            create_missing_dirs(dry_run=True)
            return 0
        if not args.yes:
            try:
                resp = input("  Mappen aanmaken? [J/n] ").strip().lower()
                if resp and resp[0] != "j":
                    print("  Geannuleerd.")
                    return 1
            except (EOFError, KeyboardInterrupt):
                print("\n  Geannuleerd.")
                return 1
        create_missing_dirs(dry_run=False)
    else:
        print("\n✓ Alle vereiste mappen bestaan al.")

    # 5. Populate system icons if requested
    if args.populate_systems:
        print("\nVullen systeem-iconen...")
        target = REQUIRED_DIRS["gameicons/systems"]
        copied = populate_system_icons(PICTURES_SYSTEMS, target, dry_run=args.dry_run)
        print(f"  {copied} iconen gekopieerd.")

    # 6. Final verification
    if not args.dry_run and not args.check_only:
        print("\n=== Eindcontrole ===")
        check_structure(args.target, verbose=True)
        check_back_jpg()
        check_emu_gameicons()
        check_system_icons()
        if args.verify:
            verify_icon_resolution()

    print("\nKlaar.")
    return 0


if __name__ == "__main__":
    sys.exit(main())