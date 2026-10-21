#!/usr/bin/env python3
"""
MobyGames HTML scraping source.
Good for retro games, no API key needed.
"""

import re
import time
from typing import Optional
import requests
from lxml import html

from sources.base import IconSource, IconResult


MOBYGAMES_BASE = "https://www.mobygames.com"
MOBYGAMES_SEARCH = MOBYGAMES_BASE + "/search/quick"


class MobyGamesSource(IconSource):
    name = "mobygames"
    rate_limit_delay = 2.0  # Be respectful

    def __init__(self, session: requests.Session | None = None):
        super().__init__(session)
        self.session.headers.update({
            "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
        })

    def search(self, query: str, system: str | None = None) -> list[IconResult]:
        """Search MobyGames for games."""
        try:
            params = {"q": query}
            if system:
                # MobyGames platform codes
                platform_map = {
                    "psx": "playstation", "ps2": "playstation2", "ps3": "playstation3",
                    "psp": "psp", "ps4": "playstation4", "ps5": "playstation5",
                    "n64": "n64", "gc": "gamecube", "wii": "wii", "wiiu": "wii-u",
                    "switch": "switch", "gb": "game-boy", "gba": "game-boy-advance",
                    "ds": "ds", "3ds": "3ds", "nes": "nes", "snes": "snes",
                    "megadrive": "genesis", "mastersystem": "master-system",
                    "gamegear": "game-gear", "saturn": "saturn", "dreamcast": "dreamcast",
                    "xbox": "xbox", "xbox360": "xbox360", "xboxone": "xbox-one",
                    "xboxseries": "xbox-series-x", "pc": "windows", "linux": "linux",
                    "mac": "macintosh", "atari2600": "atari-2600", "atari7800": "atari-7800",
                    "atarilynx": "lynx", "turbogrfx": "turbografx-16", "neogeo": "neo-geo",
                    "c64": "c64", "amiga": "amiga", "msx": "msx", "amstradcpc": "amstrad-cpc",
                    "arcade": "arcade",
                }
                platform = platform_map.get(system.lower())
                if platform:
                    params["platform"] = platform

            resp = self.session.get(MOBYGAMES_SEARCH, params=params, timeout=15)
            resp.raise_for_status()
            tree = html.fromstring(resp.content)
        except Exception as e:
            print(f"  [MobyGames] Search error: {e}")
            return []

        # Parse search results
        results = []
        game_links = tree.xpath('//a[contains(@href, "/game/")]/@href')
        game_names = tree.xpath('//a[contains(@href, "/game/")]/text()')

        for link, name in zip(game_links[:5], game_names[:5]):
            if not link or not name:
                continue
            game_url = MOBYGAMES_BASE + link
            # Get cover from game page
            cover_url = self._get_cover_url(game_url)
            if cover_url:
                results.append(IconResult(
                    url=cover_url,
                    source_name=self.name,
                    matched_name=name.strip(),
                    score=80,
                ))
        return results

    def _get_cover_url(self, game_url: str) -> Optional[str]:
        """Extract cover image URL from game page."""
        try:
            resp = self.session.get(game_url, timeout=15)
            resp.raise_for_status()
            tree = html.fromstring(resp.content)

            # Try multiple selectors for cover image
            selectors = [
                '//img[contains(@class, "cover")]/@src',
                '//div[contains(@class, "cover")]//img/@src',
                '//img[contains(@alt, "Cover")]/@src',
                '//meta[@property="og:image"]/@content',
            ]
            for sel in selectors:
                urls = tree.xpath(sel)
                if urls:
                    url = urls[0]
                    if url.startswith("//"):
                        url = "https:" + url
                    elif url.startswith("/"):
                        url = MOBYGAMES_BASE + url
                    return url
        except Exception:
            pass
        return None

    def download(self, result: IconResult) -> IconResult:
        """Download image from MobyGames."""
        try:
            resp = self.session.get(result.url, timeout=15)
            resp.raise_for_status()
            result.image_data = resp.content
        except Exception as e:
            print(f"  [MobyGames] Download error: {e}")
        return result