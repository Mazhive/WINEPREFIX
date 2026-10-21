#!/usr/bin/env python3
"""
Game Icon Scraper - Standalone utility to scrape game icons from multiple sources.

Usage:
    python3 -m scrape_icons scan [--dry-run] [--only-platforms X,Y]
    python3 -m scrape_icons scrape [--workers N] [--delay S] [--resume] [--skip-existing]
    python3 -m scrape_icons place [--force] [--skip-existing] [--no-cleanup]
    python3 -m scrape_icons verify [--fix-missing]
    python3 -m scrape_icons rebuild-index
    python3 -m scrape_icons run [--all-flags]
"""

import argparse
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from config import (
    WORK_DIR, INDEX_FILE, INDEX_BY_PATH_FILE, TEMP_ICONS_DIR,
    DEFAULT_WORKERS, DEFAULT_DELAY
)
from scanner import scan_games_root, save_index, load_index, rebuild_index
from scraper import scrape_all
from placer import place_icons, finalize_index, cleanup_temp
from verify import verify_index, print_verification_report, generate_missing_list, load_index as verify_load_index


def cmd_scan(args):
    """Scan GAMES/GAMES and build initial index."""
    print(f"[MAIN] Scanning {WORK_DIR}...")
    index = scan_games_root(
        dry_run=args.dry_run,
        only_platforms=args.only_platforms.split(",") if args.only_platforms else None
    )

    if not args.dry_run:
        save_index(index, INDEX_FILE, INDEX_BY_PATH_FILE)
        print(f"[MAIN] Index saved with {len(index)} entries")
    else:
        print(f"[MAIN] Dry run complete. Would index {len(index)} entries")


def cmd_scrape(args):
    """Scrape icons for all games in index."""
    index = load_index(INDEX_FILE)
    if not index:
        print("[MAIN] No index found. Run 'scan' first.")
        return 1

    updated = scrape_all(
        index,
        workers=args.workers,
        delay=args.delay,
        resume=args.resume,
        skip_existing=args.skip_existing
    )

    save_index(updated, INDEX_FILE, INDEX_BY_PATH_FILE)
    print("[MAIN] Scrape complete. Index updated.")


def cmd_place(args):
    """Place icons from temp to final location."""
    index = load_index(INDEX_FILE)
    if not index:
        print("[MAIN] No index found. Run 'scan' first.")
        return 1

    updated = place_icons(
        index,
        force=args.force,
        skip_existing=args.skip_existing
    )

    finalize_index(updated, INDEX_FILE, INDEX_BY_PATH_FILE)

    if not args.no_cleanup:
        cleanup_temp(confirm=not args.yes)

    print("[MAIN] Place complete.")


def cmd_verify(args):
    """Verify all icons exist and are valid."""
    index = verify_load_index(INDEX_FILE)
    if not index:
        print("[MAIN] No index found. Run 'scan' first.")
        return 1

    stats = verify_index(index, fix_missing=args.fix_missing)
    print_verification_report(stats)

    if args.fix_missing:
        missing_file = WORK_DIR / "missing_icons.json"
        generate_missing_list(stats, missing_file)


def cmd_rebuild_index(args):
    """Rebuild index files from existing data."""
    index = rebuild_index(INDEX_FILE, INDEX_BY_PATH_FILE)
    print(f"[MAIN] Index rebuilt with {len(index)} entries")


def cmd_run(args):
    """Run all phases in sequence."""
    print("=== PHASE 1: SCAN ===")
    index = scan_games_root(
        dry_run=False,
        only_platforms=args.only_platforms.split(",") if args.only_platforms else None
    )
    save_index(index, INDEX_FILE, INDEX_BY_PATH_FILE)

    print("\n=== PHASE 2: SCRAPE ===")
    index = scrape_all(
        index,
        workers=args.workers,
        delay=args.delay,
        resume=args.resume,
        skip_existing=args.skip_existing
    )
    save_index(index, INDEX_FILE, INDEX_BY_PATH_FILE)

    print("\n=== PHASE 3: PLACE ===")
    index = place_icons(
        index,
        force=args.force,
        skip_existing=args.skip_existing
    )
    finalize_index(index, INDEX_FILE, INDEX_BY_PATH_FILE)

    if not args.no_cleanup:
        cleanup_temp(confirm=not args.yes)

    print("\n=== PHASE 4: VERIFY ===")
    stats = verify_index(index)
    print_verification_report(stats)

    print("\n=== ALL DONE ===")


def main():
    parser = argparse.ArgumentParser(
        description="Game Icon Scraper - Scrape and organize game icons",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 -m scrape_icons scan --dry-run
  python3 -m scrape_icons scan --only-platforms NINTENDO,SEGA
  python3 -m scrape_icons scrape --workers 3 --delay 1.5 --resume
  python3 -m scrape_icons place --skip-existing
  python3 -m scrape_icons verify
  python3 -m scrape_icons run --workers 3 --delay 1.5
        """
    )
    parser.add_argument("--log-level", choices=["DEBUG", "INFO", "WARNING"], default="INFO")
    parser.add_argument("--yes", "-y", action="store_true", help="Auto-confirm prompts")

    subparsers = parser.add_subparsers(dest="command", required=True)

    # scan
    p_scan = subparsers.add_parser("scan", help="Scan GAMES/GAMES and build index")
    p_scan.add_argument("--dry-run", action="store_true", help="Don't save index")
    p_scan.add_argument("--only-platforms", help="Comma-separated list of platforms to scan")

    # scrape
    p_scrape = subparsers.add_parser("scrape", help="Scrape icons for indexed games")
    p_scrape.add_argument("--workers", type=int, default=DEFAULT_WORKERS, help="Parallel workers")
    p_scrape.add_argument("--delay", type=float, default=DEFAULT_DELAY, help="Delay between requests (s)")
    p_scrape.add_argument("--resume", action="store_true", help="Skip already scraped entries")
    p_scrape.add_argument("--skip-existing", action="store_true", help="Skip if temp icon exists")
    p_scrape.add_argument("--yes", "-y", action="store_true", help="Auto-confirm prompts")

    # place
    p_place = subparsers.add_parser("place", help="Move icons from temp to EMU-ICONS")
    p_place.add_argument("--force", action="store_true", help="Overwrite existing icons")
    p_place.add_argument("--skip-existing", action="store_true", help="Skip if final icon exists")
    p_place.add_argument("--no-cleanup", action="store_true", help="Don't remove temp directory")
    p_place.add_argument("--yes", "-y", action="store_true", help="Auto-confirm prompts")

    # verify
    p_verify = subparsers.add_parser("verify", help="Verify all icons exist and are valid")
    p_verify.add_argument("--fix-missing", action="store_true", help="Generate missing list file")
    p_verify.add_argument("--yes", "-y", action="store_true", help="Auto-confirm prompts")

    # rebuild-index
    p_rebuild = subparsers.add_parser("rebuild-index", help="Rebuild index files from existing data")
    p_rebuild.add_argument("--yes", "-y", action="store_true", help="Auto-confirm prompts")

    # run (all phases)
    p_run = subparsers.add_parser("run", help="Run all phases: scan → scrape → place → verify")
    p_run.add_argument("--workers", type=int, default=DEFAULT_WORKERS)
    p_run.add_argument("--delay", type=float, default=DEFAULT_DELAY)
    p_run.add_argument("--resume", action="store_true")
    p_run.add_argument("--skip-existing", action="store_true")
    p_run.add_argument("--force", action="store_true")
    p_run.add_argument("--no-cleanup", action="store_true")
    p_run.add_argument("--only-platforms", help="Comma-separated list of platforms to scan")
    p_run.add_argument("--yes", "-y", action="store_true", help="Auto-confirm prompts")

    args = parser.parse_args()

    # Ensure work directories exist
    WORK_DIR.mkdir(parents=True, exist_ok=True)
    TEMP_ICONS_DIR.mkdir(parents=True, exist_ok=True)

    # Dispatch
    commands = {
        "scan": cmd_scan,
        "scrape": cmd_scrape,
        "place": cmd_place,
        "verify": cmd_verify,
        "rebuild-index": cmd_rebuild_index,
        "run": cmd_run,
    }

    return commands[args.command](args) or 0


if __name__ == "__main__":
    sys.exit(main())