#!/usr/bin/env python3
"""
Phase 3: Place icons from temp to final EMU-ICONS location and finalize index.
"""

import json
import shutil
from pathlib import Path
from datetime import datetime

from config import EMU_ICONS_ROOT, EMU_ICONS_INDEX, TEMP_ICONS_DIR, INDEX_FILE, INDEX_BY_PATH_FILE


def place_icons(index: dict, force: bool = False, skip_existing: bool = False) -> dict:
    """
    Move icons from temp_icons to EMU-ICONS and update index with absolute paths.
    Returns updated index.
    """
    if not TEMP_ICONS_DIR.exists():
        print("[PLACE] No temp icons directory found")
        return index

    updated_index = dict(index)
    placed = 0
    skipped = 0
    missing = 0

    for rel_path, entry in index.items():
        if entry["status"] != "ok":
            continue

        temp_path = TEMP_ICONS_DIR / entry["icon_rel_path"]
        final_path = EMU_ICONS_ROOT / entry["icon_rel_path"]

        if not temp_path.exists():
            print(f"  [MISSING] Temp icon not found: {temp_path}")
            updated_index[rel_path] = {**entry, "status": "missing_temp"}
            missing += 1
            continue

        if final_path.exists() and not force:
            if skip_existing:
                print(f"  [SKIP] Already exists: {final_path}")
                updated_index[rel_path] = {
                    **entry,
                    "icon_abs_path": str(final_path),
                    "status": "skipped"
                }
                skipped += 1
                continue
            else:
                print(f"  [OVERWRITE] {final_path}")

        # Ensure target directory exists
        final_path.parent.mkdir(parents=True, exist_ok=True)

        # Move file
        try:
            shutil.move(str(temp_path), str(final_path))
            updated_index[rel_path] = {
                **entry,
                "icon_abs_path": str(final_path),
                "placed_at": datetime.utcnow().isoformat() + "Z",
                "status": "placed"
            }
            placed += 1
            print(f"  [PLACED] {rel_path} → {final_path}")
        except Exception as e:
            print(f"  [ERROR] Failed to place {rel_path}: {e}")
            updated_index[rel_path] = {**entry, "status": "place_failed", "error": str(e)}

    # Clean up empty temp directories
    _cleanup_empty_dirs(TEMP_ICONS_DIR)

    print(f"\n[PLACE] Summary: {placed} placed, {skipped} skipped, {missing} missing")
    return updated_index


def _cleanup_empty_dirs(root: Path) -> None:
    """Remove empty directories recursively."""
    for dirpath in sorted(root.rglob("*"), key=lambda p: len(p.parts), reverse=True):
        if dirpath.is_dir() and not any(dirpath.iterdir()):
            try:
                dirpath.rmdir()
            except OSError:
                pass


def finalize_index(index: dict, index_file: Path, by_path_file: Path) -> None:
    """Save final index files."""
    # Main index
    index_file.write_text(
        json.dumps(index, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8"
    )

    # By-path index
    from config import GAMES_ROOT
    by_path = {}
    for rel_path, entry in index.items():
        abs_path = str(GAMES_ROOT / rel_path)
        by_path[abs_path] = rel_path

    by_path_file.write_text(
        json.dumps(by_path, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8"
    )

    # Also write to EMU-ICONS/_index.json for the fork
    EMU_ICONS_INDEX.parent.mkdir(parents=True, exist_ok=True)
    EMU_ICONS_INDEX.write_text(
        json.dumps(index, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8"
    )

    print(f"[PLACE] Final index saved to {index_file}")
    print(f"[PLACE] By-path index saved to {by_path_file}")
    print(f"[PLACE] Fork index saved to {EMU_ICONS_INDEX}")


def cleanup_temp(confirm: bool = True, yes: bool = False) -> None:
    """Remove temp_icons directory."""
    if TEMP_ICONS_DIR.exists():
        if confirm and not yes:
            resp = input(f"Remove temp directory {TEMP_ICONS_DIR}? [Y/n] ").strip().lower()
            if resp and resp[0] != "y":
                print("[PLACE] Temp directory kept")
                return
        shutil.rmtree(TEMP_ICONS_DIR)
        print(f"[PLACE] Removed temp directory: {TEMP_ICONS_DIR}")