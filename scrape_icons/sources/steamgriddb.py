#!/usr/bin/env python3
"""
SteamGridDB API source.
Free, no rate limit, good for covers.
"""

import os
from typing import Optional
import requests
from dotenv import load_dotenv

from sources.base import IconSource, IconResult
from config import STEAMGRIDDB_API_KEY


load_dotenv()

STEAMGRIDDB_API = "https://www.steamgriddb.com/api/v2"


class SteamGridDBSource(IconSource):
    name = "steamgriddb"
    rate_limit_delay = 0.5

    def __init__(self, session: requests.Session | None = None):
        super().__init__(session)
        self.api_key = os.getenv("STEAMGRIDDB_API_KEY") or STEAMGRIDDB_API_KEY
        if self.api_key:
            self.session.headers.update({"Authorization": f"Bearer {self.api_key}"})

    def search(self, query: str, system: str | None = None) -> list[IconResult]:
        """Search SteamGridDB for games."""
        if not self.api_key:
            return []

        try:
            # Search for game by name
            resp = self.session.get(
                f"{STEAMGRIDDB_API}/search/autocomplete/{requests.utils.quote(query)}",
                timeout=15
            )
            resp.raise_for_status()
            data = resp.json()
            games = data.get("data", [])
        except Exception as e:
            print(f"  [SteamGridDB] Search error: {e}")
            return []

        results = []
        for game in games[:10]:
            game_id = game.get("id")
            if not game_id:
                continue
            # Get grids (covers) for this game
            try:
                resp = self.session.get(
                    f"{STEAMGRIDDB_API}/grids/game/{game_id}",
                    timeout=15
                )
                resp.raise_for_status()
                grids_data = resp.json()
                grids = grids_data.get("data", [])
            except Exception:
                continue

            for grid in grids:
                url = grid.get("url")
                if not url:
                    continue
                # Prefer larger images
                if "thumb" in url:
                    url = url.replace("thumb", "grid")
                results.append(IconResult(
                    url=url,
                    source_name=self.name,
                    matched_name=game.get("name", "Unknown"),
                    score=90,
                ))
        return results

    def download(self, result: IconResult) -> IconResult:
        """Download image from SteamGridDB."""
        try:
            resp = self.session.get(result.url, timeout=15)
            resp.raise_for_status()
            result.image_data = resp.content
        except Exception as e:
            print(f"  [SteamGridDB] Download error: {e}")
        return result