#!/usr/bin/env python3
"""
DuckDuckGo HTML image search source.
No API key needed, but fragile (HTML parsing).
"""

import re
import requests
from urllib.parse import quote_plus
from lxml import html

from sources.base import IconSource, IconResult


DUCKDUCKGO_HTML = "https://duckduckgo.com/html/"


class DuckDuckGoSource(IconSource):
    name = "duckduckgo"
    rate_limit_delay = 2.0

    def __init__(self, session: requests.Session | None = None):
        super().__init__(session)
        self.session.headers.update({
            "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.5",
        })

    def search(self, query: str, system: str | None = None) -> list[IconResult]:
        """Search DuckDuckGo for game cover images."""
        # Add "cover" or "box art" to query for better results
        search_query = f"{query} game cover"
        if system:
            search_query += f" {system}"

        try:
            params = {"q": search_query, "kl": "us-en"}
            resp = self.session.get(DUCKDUCKGO_HTML, params=params, timeout=15)
            resp.raise_for_status()
            tree = html.fromstring(resp.content)
        except Exception as e:
            print(f"  [DuckDuckGo] Search error: {e}")
            return []

        # Parse image results
        results = []
        # DuckDuckGo image results are in .result__snippet or similar
        img_elements = tree.xpath('//img[contains(@class, "tile--img") or contains(@class, "result__image") or @data-src]')
        
        for img in img_elements[:10]:
            src = img.get("data-src") or img.get("src")
            if not src:
                continue
            if src.startswith("//"):
                src = "https:" + src
            elif src.startswith("/"):
                src = "https://duckduckgo.com" + src
            
            # Filter out obvious non-game images
            if any(skip in src.lower() for skip in ["logo", "icon", "avatar", "profile", "banner"]):
                continue
                
            results.append(IconResult(
                url=src,
                source_name=self.name,
                matched_name=query,
                score=50,
            ))
        
        return results

    def download(self, result: IconResult) -> IconResult:
        """Download image from DuckDuckGo result."""
        try:
            resp = self.session.get(result.url, timeout=15)
            resp.raise_for_status()
            result.image_data = resp.content
        except Exception as e:
            print(f"  [DuckDuckGo] Download error: {e}")
        return result