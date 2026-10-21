#!/usr/bin/env python3
"""
Bing Images HTML scraping source.
No API key needed, scrapes Bing Images search results.
Extracts original image URLs from the 'm' attribute of iusc links.
"""

import json
import re
import requests
from lxml import html

from sources.base import IconSource, IconResult


BING_IMAGES_URL = "https://www.bing.com/images/search"

# Domains that block direct access or return unusable images
BLOCKED_DOMAINS = {
    "www.mobygames.com",
    "mobygames.com",
    "i.redd.it",
    "reddit.com",
    "redd.it",
}

# Preferred domains (high quality, reliable)
PREFERRED_DOMAINS = {
    "cdn.mobygames.com",
    "cdn.thegamesdb.net",
    "images.launchbox-app.com",
    "cdn2.steamgriddb.com",
    "steamgriddb.com",
    "i.ebayimg.com",
    "i.etsystatic.com",
    "images.igdb.com",
    "media.rawg.io",
    "cdn.cloudflare.steamstatic.com",
    "steamcdn-a.akamaihd.net",
}


class BingImagesSource(IconSource):
    name = "bing"
    rate_limit_delay = 2.0

    def __init__(self, session: requests.Session | None = None):
        super().__init__(session)
        self.session.headers.update({
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.9",
        })

    def _is_blocked(self, url: str) -> bool:
        """Check if URL is from a blocked domain."""
        try:
            domain = urlparse(url).netloc.lower()
            return any(blocked in domain for blocked in BLOCKED_DOMAINS)
        except Exception:
            return True

    def _is_preferred(self, url: str) -> bool:
        """Check if URL is from a preferred domain."""
        try:
            domain = urlparse(url).netloc.lower()
            return any(preferred in domain for preferred in PREFERRED_DOMAINS)
        except Exception:
            return False

    def search(self, query: str, system: str | None = None) -> list[IconResult]:
        """Search Bing Images for game covers, extract original image URLs."""
        search_query = f"{query} game cover"
        if system:
            search_query += f" {system}"

        try:
            params = {"q": search_query, "form": "HDRSC2", "first": 1}
            resp = self.session.get(BING_IMAGES_URL, params=params, timeout=15)
            resp.raise_for_status()
            tree = html.fromstring(resp.content)
        except Exception as e:
            print(f"  [Bing] Search error: {e}")
            return []

        # Extract original image URLs from the 'm' attribute of iusc links
        results = []
        iusc_links = tree.xpath('//a[contains(@class, "iusc")]/@m')
        
        for m_attr in iusc_links[:20]:
            try:
                data = json.loads(m_attr)
                murl = data.get("murl", "")
                if not murl:
                    continue
                
                # Skip blocked domains
                if self._is_blocked(murl):
                    continue
                
                # Skip SVG
                if murl.endswith(".svg"):
                    continue
                
                # Score: preferred domains get higher score
                score = 70 if self._is_preferred(murl) else 55
                
                results.append(IconResult(
                    url=murl,
                    source_name=self.name,
                    matched_name=query,
                    score=score,
                ))
            except (json.JSONDecodeError, KeyError):
                continue
        
        # Also try thumbnail images as fallback
        if len(results) < 5:
            img_elements = tree.xpath('//img[contains(@class, "mimg")]')
            for img in img_elements[:10]:
                src = img.get("src") or img.get("data-src")
                if not src or src.endswith(".svg"):
                    continue
                if "th?id=OIP" not in src and "mm.bing.net" not in src:
                    continue
                if not any(r.url == src for r in results):
                    results.append(IconResult(
                        url=src,
                        source_name=self.name,
                        matched_name=query,
                        score=40,
                    ))
        
        # Sort by score (preferred first)
        results.sort(key=lambda r: r.score, reverse=True)
        return results[:15]

    def download(self, result: IconResult) -> IconResult:
        """Download image from original source URL."""
        try:
            resp = self.session.get(result.url, timeout=20)
            resp.raise_for_status()
            result.image_data = resp.content
        except Exception as e:
            print(f"  [Bing] Download error: {e}")
        return result


# Need to import urlparse
from urllib.parse import urlparse