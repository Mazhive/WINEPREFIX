#!/usr/bin/env python3
"""
Matching logic for game names: fuzzy matching + manual overrides.
"""

import json
import re
from pathlib import Path
from typing import Optional

from rapidfuzz import fuzz, process

from config import MANUAL_MAPPING_FILE, FOLDER_TO_EMU_SYSTEM, PRETTIFY_SPLIT_RE, CAMEL_CASE_RE


# ─── Manual Mapping Cache ────────────────────────────────────────────────────
_MANUAL_MAPPING: dict | None = None


def load_manual_mapping() -> dict:
    """Load manual mapping from JSON file."""
    global _MANUAL_MAPPING
    if _MANUAL_MAPPING is not None:
        return _MANUAL_MAPPING
    if MANUAL_MAPPING_FILE.exists():
        try:
            _MANUAL_MAPPING = json.loads(MANUAL_MAPPING_FILE.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            _MANUAL_MAPPING = {}
    else:
        _MANUAL_MAPPING = {}
    return _MANUAL_MAPPING


def save_manual_mapping(mapping: dict) -> None:
    """Save manual mapping to JSON file."""
    global _MANUAL_MAPPING
    _MANUAL_MAPPING = mapping
    MANUAL_MAPPING_FILE.write_text(
        json.dumps(mapping, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8"
    )


def get_manual_override(rel_path: str, folder_name: str) -> Optional[str]:
    """Get manual search term override for a folder name or full path."""
    mapping = load_manual_mapping()
    # Try full path first, then folder name
    return mapping.get(rel_path) or mapping.get(folder_name)


def add_manual_override(folder_name: str, search_term: str) -> None:
    """Add a manual override."""
    mapping = load_manual_mapping()
    mapping[folder_name] = search_term
    save_manual_mapping(mapping)


# ─── Prettify Logic (from game-gui-fork.py) ──────────────────────────────────
def prettify(key: str) -> str:
    """Convert a folder name to a display name."""
    parts = PRETTIFY_SPLIT_RE.split(key)
    parts = [p for p in parts if p]
    words = []
    for p in parts:
        sub = CAMEL_CASE_RE.sub(r"\1 \2", p)
        words.extend(w for w in sub.split(" ") if w)
    return " ".join(w[:1].upper() + w[1:] for w in words)


def normalize_for_matching(name: str) -> str:
    """Normalize a name for fuzzy matching (lowercase, alphanumeric only)."""
    return re.sub(r"[^a-z0-9]", "", name.lower())


# ─── Search Term Generation ──────────────────────────────────────────────────
def generate_search_terms(rel_path: str, platform_name: str, system_folder: str, folder_name: str) -> list[str]:
    """Generate ordered search terms for a game."""
    terms = []

    # 1. Manual override (highest priority) - use as complete search term
    manual = get_manual_override(rel_path, folder_name)
    if manual:
        terms.append(manual)
        # Also add manual + system for broader matching
        system_key = FOLDER_TO_EMU_SYSTEM.get(system_folder.upper(), system_folder.lower())
        terms.append(f"{manual} {system_key}")

    # 2. Prettified display name + system
    display_name = prettify(folder_name)
    system_key = FOLDER_TO_EMU_SYSTEM.get(system_folder.upper(), system_folder.lower())
    terms.append(f"{display_name} {system_key}")

    # 3. Display name alone
    terms.append(display_name)

    # 4. Raw folder name + system
    terms.append(f"{folder_name} {system_key}")

    # 5. Raw folder name
    terms.append(folder_name)

    # Deduplicate while preserving order
    seen = set()
    unique_terms = []
    for t in terms:
        norm = normalize_for_matching(t)
        if norm not in seen:
            seen.add(norm)
            unique_terms.append(t)

    return unique_terms


# ─── Fuzzy Matching ──────────────────────────────────────────────────────────
def fuzzy_match(query: str, candidates: list[str], threshold: int = 70) -> Optional[tuple[str, int]]:
    """Find best fuzzy match for query in candidates."""
    if not candidates:
        return None
    result = process.extractOne(query, candidates, scorer=fuzz.WRatio)
    if result and result[1] >= threshold:
        return result[0], result[1]
    return None


def find_best_match(search_terms: list[str], candidates: list[str], threshold: int = 70) -> Optional[tuple[str, str, int]]:
    """Try multiple search terms against candidates, return (matched_candidate, search_term, score)."""
    for term in search_terms:
        match = fuzzy_match(term, candidates, threshold)
        if match:
            return match[0], term, match[1]
    return None