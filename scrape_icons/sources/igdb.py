#!/usr/bin/env python3
"""
IGDB (Internet Game Database) API source.
Requires Twitch OAuth: Client ID + Client Secret.
"""

import os
import time
from typing import Optional
import requests
from dotenv import load_dotenv

from sources.base import IconSource, IconResult
from config import IGDB_CLIENT_ID, IGDB_CLIENT_SECRET


# Load .env if exists
load_dotenv()

IGDB_TOKEN_URL = "https://id.twitch.tv/oauth2/token"
IGDB_API_URL = "https://api.igdb.com/v4"
IGDB_IMAGES_BASE = "https://images.igdb.com/igdb/image/upload/t_cover_big"


class IGDBSource(IconSource):
    name = "igdb"
    rate_limit_delay = 0.25  # 4 requests/second limit

    def __init__(self, session: requests.Session | None = None):
        super().__init__(session)
        self.client_id = os.getenv("IGDB_CLIENT_ID") or IGDB_CLIENT_ID
        self.client_secret = os.getenv("IGDB_CLIENT_SECRET") or IGDB_CLIENT_SECRET
        self._access_token: str | None = None
        self._token_expiry: float = 0

    def _get_token(self) -> str:
        """Get or refresh OAuth token."""
        if self._access_token and time.time() < self._token_expiry - 60:
            return self._access_token

        if not self.client_id or not self.client_secret:
            raise ValueError("IGDB_CLIENT_ID and IGDB_CLIENT_SECRET must be set in .env")

        resp = self.session.post(IGDB_TOKEN_URL, data={
            "client_id": self.client_id,
            "client_secret": self.client_secret,
            "grant_type": "client_credentials"
        }, timeout=10)
        resp.raise_for_status()
        data = resp.json()
        self._access_token = data["access_token"]
        self._token_expiry = time.time() + data["expires_in"]
        return self._access_token

    def _headers(self) -> dict:
        return {
            "Client-ID": self.client_id,
            "Authorization": f"Bearer {self._get_token()}",
            "Accept": "application/json",
        }

    def search(self, query: str, system: str | None = None) -> list[IconResult]:
        """Search IGDB for games matching query."""
        if not self.client_id or not self.client_secret:
            return []

        # Build query: search by name, filter by platform if system provided
        # IGDB platform IDs: https://api-docs.igdb.com/#platforms
        platform_map = {
            "psx": 7, "ps2": 8, "ps3": 9, "psp": 38, "ps4": 48, "ps5": 167,
            "n64": 4, "gc": 5, "wii": 5, "wiiu": 41, "switch": 130,
            "gb": 24, "gba": 25, "ds": 20, "3ds": 37,
            "nes": 18, "snes": 19, "famicom": 18,
            "megadrive": 29, "mastersystem": 30, "gamegear": 31,
            "saturn": 32, "dreamcast": 23,
            "xbox": 11, "xbox360": 12, "xboxone": 49, "xboxseries": 169,
            "pc": 6, "linux": 14, "mac": 15,
            "atari2600": 13, "atari7800": 33, "atarilynx": 34,
            "turbogrfx": 35, "neogeo": 36,
            "c64": 16, "amiga": 17, "c128": 16, "vic20": 16,
            "msx": 21, "amstradcpc": 22,
            "arcade": 27,
        }

        platform_id = platform_map.get(system.lower()) if system else None

        # IGDB query language
        where_clauses = [f'name ~ *"{query}"*']
        if platform_id:
            where_clauses.append(f"platforms = {platform_id}")
        where_str = " & ".join(where_clauses)

        body = f"""
            fields name, cover.url, first_release_date, platforms, summary;
            where {where_str};
            limit 10;
            sort first_release_date desc;
        """

        try:
            resp = self.session.post(
                f"{IGDB_API_URL}/games",
                headers=self._headers(),
                data=body,
                timeout=15
            )
            resp.raise_for_status()
            games = resp.json()
        except Exception as e:
            print(f"  [IGDB] Search error: {e}")
            return []

        results = []
        for game in games:
            cover = game.get("cover")
            if not cover or not cover.get("url"):
                continue
            # Convert IGDB image URL to high-res
            url = cover["url"].replace("t_thumb", "t_cover_big")
            if url.startswith("//"):
                url = "https:" + url
            results.append(IconResult(
                url=url,
                source_name=self.name,
                matched_name=game.get("name", "Unknown"),
                score=100,  # IGDB results are already filtered
            ))
        return results

    def download(self, result: IconResult) -> IconResult:
        """Download image from IGDB."""
        try:
            resp = self.session.get(result.url, timeout=15)
            resp.raise_for_status()
            result.image_data = resp.content
        except Exception as e:
            print(f"  [IGDB] Download error: {e}")
        return result