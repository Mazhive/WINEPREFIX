#!/usr/bin/env python3
"""
Base class for icon sources.
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass
from pathlib import Path
from typing import Optional
import requests
from PIL import Image


@dataclass
class IconResult:
    """Result of an icon search/download."""
    url: str
    source_name: str
    matched_name: str
    score: int
    image_data: bytes | None = None
    image_path: Path | None = None

    def validate_image(self, min_width: int = 256, min_height: int = 256,
                       max_aspect: float = 2.0, min_aspect: float = 0.5) -> bool:
        """Validate downloaded image meets requirements."""
        if not self.image_data:
            return False
        try:
            import io
            img = Image.open(io.BytesIO(self.image_data))
            w, h = img.size
            if w < min_width or h < min_height:
                return False
            aspect = w / h
            if aspect > max_aspect or aspect < min_aspect:
                return False
            return True
        except Exception:
            return False


class IconSource(ABC):
    """Abstract base class for icon sources."""

    name: str = "base"
    rate_limit_delay: float = 1.0  # seconds between requests

    def __init__(self, session: requests.Session | None = None):
        self.session = session or requests.Session()
        self.session.headers.update({
            "User-Agent": "GameIconScraper/1.0 (+https://github.com/)"
        })

    @abstractmethod
    def search(self, query: str, system: str | None = None) -> list[IconResult]:
        """Search for icons matching query. Returns list of results (best first)."""
        pass

    @abstractmethod
    def download(self, result: IconResult) -> IconResult:
        """Download the icon image data. Returns updated result with image_data."""
        pass

    def search_and_download(self, query: str, system: str | None = None,
                            min_width: int = 256, min_height: int = 256,
                            max_aspect: float = 2.0, min_aspect: float = 0.5) -> Optional[IconResult]:
        """Convenience: search and download first valid result."""
        results = self.search(query, system)
        for r in results:
            r = self.download(r)
            if r.validate_image(min_width, min_height, max_aspect, min_aspect):
                return r
        return None

    def close(self):
        """Close the session."""
        self.session.close()

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()