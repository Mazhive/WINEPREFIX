#!/usr/bin/env python3
"""
Wikipedia/Wikidata API source.
Free, no key needed, fallback for metadata.
"""

import requests
from typing import Optional

from sources.base import IconSource, IconResult


WIKIPEDIA_API = "https://en.wikipedia.org/w/api.php"
WIKIDATA_API = "https://www.wikidata.org/w/api.php"


class WikipediaSource(IconSource):
    name = "wikipedia"
    rate_limit_delay = 1.0

    def search(self, query: str, system: str | None = None) -> list[IconResult]:
        """Search Wikipedia for game page and get main image."""
        # Search for page
        try:
            search_params = {
                "action": "query",
                "list": "search",
                "srsearch": query,
                "srlimit": 5,
                "format": "json",
            }
            resp = self.session.get(WIKIPEDIA_API, params=search_params, timeout=15)
            resp.raise_for_status()
            data = resp.json()
            pages = data.get("query", {}).get("search", [])
        except Exception as e:
            print(f"  [Wikipedia] Search error: {e}")
            return []

        results = []
        for page in pages[:3]:
            page_id = page.get("pageid")
            title = page.get("title", "")
            if not page_id:
                continue

            # Get page image
            image_url = self._get_page_image(page_id)
            if image_url:
                results.append(IconResult(
                    url=image_url,
                    source_name=self.name,
                    matched_name=title,
                    score=60,
                ))
        return results

    def _get_page_image(self, page_id: int) -> Optional[str]:
        """Get main image from Wikipedia page."""
        try:
            params = {
                "action": "query",
                "prop": "pageimages",
                "pageids": page_id,
                "piprop": "original",
                "format": "json",
            }
            resp = self.session.get(WIKIPEDIA_API, params=params, timeout=15)
            resp.raise_for_status()
            data = resp.json()
            pages = data.get("query", {}).get("pages", {})
            page = pages.get(str(page_id), {})
            return page.get("original", {}).get("source")
        except Exception:
            return None

    def download(self, result: IconResult) -> IconResult:
        """Download image from Wikipedia."""
        try:
            resp = self.session.get(result.url, timeout=15)
            resp.raise_for_status()
            result.image_data = resp.content
        except Exception as e:
            print(f"  [Wikipedia] Download error: {e}")
        return result


class WikidataSource(IconSource):
    """Wikidata source for structured data + images."""
    name = "wikidata"
    rate_limit_delay = 1.0

    def search(self, query: str, system: str | None = None) -> list[IconResult]:
        """Search Wikidata for game entity."""
        try:
            params = {
                "action": "wbsearchentities",
                "search": query,
                "language": "en",
                "type": "item",
                "limit": 5,
                "format": "json",
            }
            resp = self.session.get(WIKIDATA_API, params=params, timeout=15)
            resp.raise_for_status()
            data = resp.json()
            entities = data.get("search", [])
        except Exception as e:
            print(f"  [Wikidata] Search error: {e}")
            return []

        results = []
        for entity in entities[:3]:
            entity_id = entity.get("id")
            label = entity.get("label", "")
            if not entity_id:
                continue

            # Get image from entity
            image_url = self._get_entity_image(entity_id)
            if image_url:
                results.append(IconResult(
                    url=image_url,
                    source_name=self.name,
                    matched_name=label,
                    score=65,
                ))
        return results

    def _get_entity_image(self, entity_id: str) -> Optional[str]:
        """Get image (P18) from Wikidata entity."""
        try:
            params = {
                "action": "wbgetclaims",
                "entity": entity_id,
                "property": "P18",  # image
                "format": "json",
            }
            resp = self.session.get(WIKIDATA_API, params=params, timeout=15)
            resp.raise_for_status()
            data = resp.json()
            claims = data.get("claims", {}).get("P18", [])
            if claims:
                filename = claims[0].get("mainsnak", {}).get("datavalue", {}).get("value")
                if filename:
                    # Get image URL from Wikimedia Commons
                    return self._get_commons_url(filename)
        except Exception:
            pass
        return None

    def _get_commons_url(self, filename: str) -> Optional[str]:
        """Get direct image URL from Wikimedia Commons."""
        try:
            params = {
                "action": "query",
                "titles": f"File:{filename}",
                "prop": "imageinfo",
                "iiprop": "url",
                "iiurlwidth": 800,
                "format": "json",
            }
            resp = self.session.get(WIKIPEDIA_API, params=params, timeout=15)
            resp.raise_for_status()
            data = resp.json()
            pages = data.get("query", {}).get("pages", {})
            for page in pages.values():
                info = page.get("imageinfo", [])
                if info:
                    return info[0].get("url")
        except Exception:
            pass
        return None

    def download(self, result: IconResult) -> IconResult:
        """Download image from Wikimedia Commons."""
        try:
            resp = self.session.get(result.url, timeout=15)
            resp.raise_for_status()
            result.image_data = resp.content
        except Exception as e:
            print(f"  [Wikidata] Download error: {e}")
        return result