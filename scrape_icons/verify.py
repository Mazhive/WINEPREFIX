#!/usr/bin/env python3
"""
Phase 4: Verify all index entries have valid icons in EMU-ICONS.
"""

import json
from pathlib import Path
from PIL import Image

from config import EMU_ICONS_ROOT, INDEX_FILE, INDEX_BY_PATH_FILE, MIN_ICON_WIDTH, MIN_ICON_HEIGHT


def verify_index(index: dict, fix_missing: bool = False) -> dict:
    """
    Verify all entries in index have valid icon files.
    Returns summary dict.
    """
    stats = {
        "total": len(index),
        "ok": 0,
        "missing_file": 0,
        "corrupt": 0,
        "too_small": 0,
        "wrong_status": 0,
        "details": []
    }

    for rel_path, entry in index.items():
        icon_rel = entry.get("icon_rel_path")
        icon_abs = entry.get("icon_abs_path")
        status = entry.get("status", "unknown")

        if not icon_rel:
            stats["missing_file"] += 1
            stats["details"].append({
                "rel_path": rel_path,
                "issue": "no_icon_rel_path",
                "status": status
            })
            continue

        # Check absolute path
        if icon_abs:
            final_path = Path(icon_abs)
        else:
            final_path = EMU_ICONS_ROOT / icon_rel

        if not final_path.exists():
            stats["missing_file"] += 1
            stats["details"].append({
                "rel_path": rel_path,
                "issue": "file_not_found",
                "expected_path": str(final_path),
                "status": status
            })
            continue

        # Validate image
        try:
            with Image.open(final_path) as img:
                w, h = img.size
                if w < MIN_ICON_WIDTH or h < MIN_ICON_HEIGHT:
                    stats["too_small"] += 1
                    stats["details"].append({
                        "rel_path": rel_path,
                        "issue": "too_small",
                        "size": f"{w}x{h}",
                        "status": status
                    })
                    continue
        except Exception as e:
            stats["corrupt"] += 1
            stats["details"].append({
                "rel_path": rel_path,
                "issue": "corrupt",
                "error": str(e),
                "status": status
            })
            continue

        # Check status consistency
        if status not in ("ok", "placed"):
            stats["wrong_status"] += 1
            stats["details"].append({
                "rel_path": rel_path,
                "issue": "wrong_status",
                "status": status
            })
            continue

        stats["ok"] += 1

    return stats


def print_verification_report(stats: dict) -> None:
    """Print human-readable verification report."""
    print(f"\n=== VERIFICATION REPORT ===")
    print(f"Total entries:     {stats['total']}")
    print(f"✓ OK:              {stats['ok']}")
    print(f"✗ Missing file:    {stats['missing_file']}")
    print(f"✗ Corrupt:         {stats['corrupt']}")
    print(f"✗ Too small:       {stats['too_small']}")
    print(f"⚠ Wrong status:    {stats['wrong_status']}")

    if stats["details"]:
        print(f"\n--- Issues ---")
        for d in stats["details"]:
            print(f"  {d['rel_path']}: {d['issue']} ({d.get('status', 'N/A')})")


def generate_missing_list(stats: dict, output_file: Path) -> None:
    """Generate a list of games missing icons for manual fixing."""
    missing = [d for d in stats["details"] if d["issue"] in ("file_not_found", "no_icon_rel_path")]
    if missing:
        output_file.write_text(
            json.dumps(missing, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8"
        )
        print(f"\n[VERIFY] Missing list saved to {output_file} ({len(missing)} entries)")


def load_index(index_file: Path) -> dict:
    """Load index from JSON file."""
    if not index_file.exists():
        return {}
    try:
        return json.loads(index_file.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError) as e:
        print(f"[VERIFY] Error loading index: {e}")
        return {}