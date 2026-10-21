#!/usr/bin/env python3
"""
Phase 1: Scan GAMES/GAMES directory and build initial index.
"""

import json
import os
from pathlib import Path
from typing import Optional

from config import (
    GAMES_ROOT, SKIP_PLATFORM_DIRS, FOLDER_TO_EMU_SYSTEM,
    PLATFORM_TITLES, JUNK_EXTS, JUNK_NAMES, BUCKET_THRESHOLD,
    PRETTIFY_SPLIT_RE, CAMEL_CASE_RE
)
from matching import prettify, generate_search_terms


# Known extracted game data folder names (not actual game folders)
EXTRACTED_DATA_FOLDERS = {
    "data", "media", "audio", "video", "movies", "tracks", "cars", "actors",
    "frontend", "drivers", "scenarios", "cursors", "foodata", "tracks",
    "gamedatabin", "psm", "videos", "particle", "text", "eagl",
    "_bronnen", ".petmp35f5a4", ".petmp372da4", ".petmp8d747b",
    ".petmp13fb0c", "iii", "px-cod3",
}


def is_junk(name: str) -> bool:
    """Check if a file/folder name is junk."""
    if name in JUNK_NAMES:
        return True
    ext = os.path.splitext(name)[1].lower()
    if ext in JUNK_EXTS:
        return True
    # Check for extracted data folders (case-insensitive)
    if name.lower() in EXTRACTED_DATA_FOLDERS:
        return True
    return False


def has_game_files(folder: Path) -> bool:
    """Check if folder contains game files (not just junk)."""
    try:
        for item in folder.iterdir():
            if item.is_file() and not is_junk(item.name):
                return True
            if item.is_dir() and not is_junk(item.name):
                # Recurse one level for nested game files
                for sub in item.iterdir():
                    if sub.is_file() and not is_junk(sub.name):
                        return True
        return False
    except (OSError, PermissionError):
        return False


def get_game_subdirs(system_dir: Path) -> list[Path]:
    """Get subdirectories that contain game files."""
    subdirs = []
    for d in system_dir.iterdir():
        if d.is_dir() and not is_junk(d.name):
            if has_game_files(d):
                subdirs.append(d)
    return sorted(subdirs)


def scan_games_root(dry_run: bool = False, only_platforms: list[str] | None = None) -> dict:
    """
    Scan GAMES/GAMES and build index of all leaf folders containing games.
    Handles two structures:
    1. Platform/System/GameFolder/ (game files in subfolder)
    2. Platform/System/ (game files directly in system folder)
    Returns dict: relative_path -> entry_dict
    """
    index = {}
    platforms_scanned = 0
    systems_scanned = 0
    games_found = 0

    if not GAMES_ROOT.exists():
        print(f"[SCAN] ERROR: Games root not found: {GAMES_ROOT}")
        return index

    platform_dirs = sorted([d for d in GAMES_ROOT.iterdir() if d.is_dir()])
    for platform_dir in platform_dirs:
        platform_name = platform_dir.name

        if platform_name in SKIP_PLATFORM_DIRS:
            if not dry_run:
                print(f"[SCAN] Skipping platform: {platform_name}")
            continue

        if only_platforms and platform_name not in only_platforms:
            continue

        platforms_scanned += 1
        if not dry_run:
            print(f"[SCAN] Platform: {platform_name}")

        # Scan system directories (level 2)
        system_dirs = sorted([d for d in platform_dir.iterdir() if d.is_dir()])
        for system_dir in system_dirs:
            system_name = system_dir.name
            emu_system = FOLDER_TO_EMU_SYSTEM.get(system_name.upper(), system_name.lower())

            systems_scanned += 1

            # Check if system folder has game subdirectories
            game_subdirs = get_game_subdirs(system_dir)

            if game_subdirs:
                # Case 1: Game files in subfolders (Platform/System/GameFolder/)
                for game_dir in game_subdirs:
                    game_folder_name = game_dir.name

                    games_found += 1
                    rel_path = f"{platform_name}/{system_name}/{game_folder_name}"
                    display_name = prettify(game_folder_name)
                    search_terms = generate_search_terms(rel_path, platform_name, system_name, game_folder_name)

                    icon_rel_path = f"{platform_name}/{system_name}/{display_name}.png"

                    entry = {
                        "platform": platform_name,
                        "system": emu_system,
                        "system_folder": system_name,
                        "folder_name": game_folder_name,
                        "display_name": display_name,
                        "icon_rel_path": icon_rel_path,
                        "icon_abs_path": None,
                        "search_terms": search_terms,
                        "source": None,
                        "matched_name": None,
                        "scraped_at": None,
                        "status": "pending",
                    }
                    index[rel_path] = entry

                    if not dry_run:
                        print(f"  [FOUND] {rel_path} → {display_name} (system: {emu_system})")
            else:
                # Case 2: Game files directly in system folder (Platform/System/*.rom)
                # Check if system folder itself has game files
                if has_game_files(system_dir):
                    games_found += 1
                    # Use system name as the "game folder" name
                    rel_path = f"{platform_name}/{system_name}"
                    display_name = PLATFORM_TITLES.get(platform_name, platform_name) + " " + system_name
                    search_terms = generate_search_terms(rel_path, platform_name, system_name, system_name)

                    icon_rel_path = f"{platform_name}/{system_name}/{display_name}.png"

                    entry = {
                        "platform": platform_name,
                        "system": emu_system,
                        "system_folder": system_name,
                        "folder_name": system_name,  # System folder itself
                        "display_name": display_name,
                        "icon_rel_path": icon_rel_path,
                        "icon_abs_path": None,
                        "search_terms": search_terms,
                        "source": None,
                        "matched_name": None,
                        "scraped_at": None,
                        "status": "pending",
                    }
                    index[rel_path] = entry

                    if not dry_run:
                        print(f"  [FOUND] {rel_path} → {display_name} (system: {emu_system}) [system-level]")
                elif not dry_run:
                    print(f"  [SKIP] No game files: {platform_name}/{system_name}")

    if not dry_run:
        print(f"\n[SCAN] Summary: {platforms_scanned} platforms, {systems_scanned} systems, {games_found} games")
        print(f"[SCAN] Index entries: {len(index)}")

    return index


def save_index(index: dict, index_file: Path, by_path_file: Path) -> None:
    """Save index to JSON files."""
    # Main index (key = relative path)
    index_file.write_text(
        json.dumps(index, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8"
    )

    # By-path index (key = absolute folder path)
    by_path = {}
    for rel_path, entry in index.items():
        abs_path = str(GAMES_ROOT / rel_path)
        by_path[abs_path] = rel_path

    by_path_file.write_text(
        json.dumps(by_path, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8"
    )

    print(f"[SCAN] Saved index to {index_file}")
    print(f"[SCAN] Saved by-path index to {by_path_file}")


def load_index(index_file: Path) -> dict:
    """Load index from JSON file."""
    if not index_file.exists():
        return {}
    try:
        return json.loads(index_file.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError) as e:
        print(f"[SCAN] Error loading index: {e}")
        return {}


def rebuild_index(index_file: Path, by_path_file: Path) -> dict:
    """Rebuild index from existing data (after manual edits)."""
    index = load_index(index_file)
    save_index(index, index_file, by_path_file)
    return index