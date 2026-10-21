#!/usr/bin/env python3
"""
Match existing icons in GAMEICONS root to indexed games and copy to EMU-ICONS.
"""

import json
import shutil
from pathlib import Path
from rapidfuzz import fuzz, process

from config import ICONS_ROOT, EMU_ICONS_ROOT, INDEX_FILE, INDEX_BY_PATH_FILE, WORK_DIR
from scanner import load_index, save_index
from matching import normalize_for_matching, load_manual_mapping


ICON_NAME_MAPPING_FILE = WORK_DIR / "icon_name_mapping.json"


def load_icon_name_mapping() -> dict:
    """Load icon filename to game name mapping."""
    if ICON_NAME_MAPPING_FILE.exists():
        try:
            return json.loads(ICON_NAME_MAPPING_FILE.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            return {}
    return {}


def match_existing_icons(index: dict, threshold: int = 95) -> dict:
    """
    Match existing icons in ICONS_ROOT to index entries.
    Returns updated index with matched icons copied to EMU_ICONS_ROOT.
    """
    # Get all existing icons in root
    existing_icons = {}
    icon_name_mapping = load_icon_name_mapping()
    
    for icon_file in ICONS_ROOT.glob("*.png"):
        if icon_file.name == "back.jpg":
            continue
        stem = icon_file.stem
        norm = normalize_for_matching(stem)
        existing_icons[norm] = icon_file
        # Also add mapped name
        if stem in icon_name_mapping:
            mapped_norm = normalize_for_matching(icon_name_mapping[stem])
            existing_icons[mapped_norm] = icon_file
    
    # Also check for .jpg files
    for icon_file in ICONS_ROOT.glob("*.jpg"):
        if icon_file.name == "back.jpg":
            continue
        stem = icon_file.stem
        norm = normalize_for_matching(stem)
        existing_icons[norm] = icon_file
        if stem in icon_name_mapping:
            mapped_norm = normalize_for_matching(icon_name_mapping[stem])
            existing_icons[mapped_norm] = icon_file
    
    print(f"[MATCH] Found {len(existing_icons)} existing icons in {ICONS_ROOT} (with mappings)")
    
    # Load manual mappings
    manual_mapping = load_manual_mapping()
    
    updated_index = dict(index)
    matched = 0
    copied = 0
    
    for rel_path, entry in index.items():
        if entry["status"] in ("ok", "placed"):
            continue
            
        # Build list of names to try for matching
        names_to_try = []
        
        # 1. Search terms (which include manual mappings as first priority)
        for term in entry.get("search_terms", []):
            names_to_try.append(term)
        
        # 2. Display name
        names_to_try.append(entry["display_name"])
        
        # 3. Folder name
        names_to_try.append(entry["folder_name"])
        
        # Normalize and deduplicate
        tried = set()
        for name in names_to_try:
            norm = normalize_for_matching(name)
            if norm and norm not in tried:
                tried.add(norm)
                
                # Try exact match
                if norm in existing_icons:
                    src = existing_icons[norm]
                    dst = EMU_ICONS_ROOT / entry["icon_rel_path"]
                    dst.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(src, dst)
                    updated_index[rel_path] = {
                        **entry,
                        "icon_abs_path": str(dst),
                        "source": "existing_local",
                        "matched_name": name,
                        "status": "placed"
                    }
                    matched += 1
                    copied += 1
                    print(f"  [MATCH] Exact: {rel_path} → {src.name} (via '{name}')")
                    break
                
                # Try fuzzy match
                match = process.extractOne(
                    norm,
                    list(existing_icons.keys()),
                    scorer=fuzz.WRatio,
                    score_cutoff=threshold
                )
                
                if match:
                    matched_norm, score, _ = match
                    src = existing_icons[matched_norm]
                    dst = EMU_ICONS_ROOT / entry["icon_rel_path"]
                    dst.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(src, dst)
                    updated_index[rel_path] = {
                        **entry,
                        "icon_abs_path": str(dst),
                        "source": "existing_local_fuzzy",
                        "matched_name": name,
                        "status": "placed"
                    }
                    matched += 1
                    copied += 1
                    print(f"  [MATCH] Fuzzy ({score}%): {rel_path} → {src.name} (via '{name}')")
                    break
    
    print(f"\n[MATCH] Summary: {matched} matched, {copied} copied to EMU-ICONS")
    return updated_index


def main():
    index = load_index(INDEX_FILE)
    if not index:
        print("No index found. Run scan first.")
        return
    
    updated = match_existing_icons(index)
    save_index(updated, INDEX_FILE, INDEX_BY_PATH_FILE)
    print("[MATCH] Done.")


if __name__ == "__main__":
    main()