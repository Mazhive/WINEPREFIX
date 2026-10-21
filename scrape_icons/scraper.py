#!/usr/bin/env python3
"""
Phase 2: Scrape icons for all games in index.
"""

import json
import time
import shutil
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Optional
from datetime import datetime

from config import (
    WORK_DIR, TEMP_ICONS_DIR, INDEX_FILE, LOG_FILE,
    SOURCE_PRIORITY, DEFAULT_WORKERS, DEFAULT_DELAY,
    MIN_ICON_WIDTH, MIN_ICON_HEIGHT, MAX_ASPECT_RATIO, MIN_ASPECT_RATIO
)
from sources import get_all_sources, close_all
from matching import find_best_match


def load_log() -> list:
    """Load scrape log."""
    if LOG_FILE.exists():
        try:
            return json.loads(LOG_FILE.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            return []
    return []


def save_log(log: list) -> None:
    """Save scrape log."""
    LOG_FILE.write_text(
        json.dumps(log, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8"
    )


def log_entry(log: list, rel_path: str, status: str, **kwargs) -> None:
    """Add entry to log."""
    entry = {
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "rel_path": rel_path,
        "status": status,
        **kwargs
    }
    log.append(entry)


def scrape_game(rel_path: str, entry: dict, sources: list, delay: float,
                skip_existing: bool = False) -> tuple[str, dict, Optional[Path]]:
    """
    Scrape icon for a single game.
    Returns: (rel_path, updated_entry, temp_icon_path or None)
    """
    display_name = entry["display_name"]
    search_terms = entry["search_terms"]
    system = entry["system"]

    # Check if already has icon in temp
    temp_icon_path = TEMP_ICONS_DIR / entry["icon_rel_path"]
    if skip_existing and temp_icon_path.exists():
        return rel_path, {**entry, "status": "skipped", "source": "existing"}, temp_icon_path

    # Try each source in priority order
    for source in sources:
        time.sleep(delay)  # Rate limiting per worker

        for term in search_terms:
            try:
                result = source.search_and_download(
                    term, system,
                    min_width=MIN_ICON_WIDTH,
                    min_height=MIN_ICON_HEIGHT,
                    max_aspect=MAX_ASPECT_RATIO,
                    min_aspect=MIN_ASPECT_RATIO
                )
                if result:
                    # Save to temp location
                    temp_icon_path.parent.mkdir(parents=True, exist_ok=True)
                    with open(temp_icon_path, "wb") as f:
                        f.write(result.image_data)

                    updated = {
                        **entry,
                        "status": "ok",
                        "source": result.source_name,
                        "matched_name": result.matched_name,
                        "scraped_at": datetime.utcnow().isoformat() + "Z",
                    }
                    return rel_path, updated, temp_icon_path
            except Exception as e:
                print(f"  [SCRAPE] {source.name} error for '{term}': {e}")
                continue

    # All sources failed
    return rel_path, {**entry, "status": "failed"}, None


def scrape_all(index: dict, workers: int = DEFAULT_WORKERS, delay: float = DEFAULT_DELAY,
               resume: bool = False, skip_existing: bool = False) -> dict:
    """
    Scrape icons for all games in index.
    Returns updated index.
    """
    log = load_log()
    sources = get_all_sources()

    # Filter entries that need scraping
    to_scrape = {}
    for rel_path, entry in index.items():
        if entry["status"] in ("ok", "skipped") and resume:
            continue
        if entry["status"] == "ok" and skip_existing:
            continue
        to_scrape[rel_path] = entry

    print(f"[SCRAPE] Total entries: {len(index)}, to scrape: {len(to_scrape)}")
    print(f"[SCRAPE] Workers: {workers}, Delay: {delay}s")
    print(f"[SCRAPE] Sources: {[s.name for s in sources]}")

    if not to_scrape:
        close_all(sources)
        return index

    updated_index = dict(index)
    completed = 0
    failed = 0

    with ThreadPoolExecutor(max_workers=workers) as executor:
        futures = {
            executor.submit(scrape_game, rel_path, entry, sources, delay, skip_existing): rel_path
            for rel_path, entry in to_scrape.items()
        }

        for future in as_completed(futures):
            rel_path = futures[future]
            try:
                rel_path, updated_entry, temp_path = future.result()
                updated_index[rel_path] = updated_entry

                if updated_entry["status"] == "ok":
                    completed += 1
                    print(f"  [OK] {rel_path} → {updated_entry['source']} ({updated_entry['matched_name']})")
                elif updated_entry["status"] == "skipped":
                    completed += 1
                    print(f"  [SKIP] {rel_path} (already exists)")
                else:
                    failed += 1
                    print(f"  [FAIL] {rel_path}")

                log_entry(log, rel_path, updated_entry["status"],
                          source=updated_entry.get("source"),
                          matched_name=updated_entry.get("matched_name"))

            except Exception as e:
                failed += 1
                print(f"  [ERROR] {rel_path}: {e}")
                log_entry(log, rel_path, "error", error=str(e))

            # Save progress periodically
            if (completed + failed) % 10 == 0:
                save_log(log)

    close_all(sources)
    save_log(log)

    print(f"\n[SCRAPE] Complete: {completed} ok/skipped, {failed} failed")
    return updated_index