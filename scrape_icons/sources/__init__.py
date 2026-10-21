#!/usr/bin/env python3
"""
Source registry and factory.
"""

from sources.base import IconSource
from sources.igdb import IGDBSource
from sources.steamgriddb import SteamGridDBSource
from sources.mobygames import MobyGamesSource
from sources.wikipedia import WikipediaSource, WikidataSource
from sources.duckduckgo import DuckDuckGoSource
from sources.bing import BingImagesSource
from config import SOURCE_PRIORITY


# Registry of available sources
SOURCE_CLASSES = {
    "igdb": IGDBSource,
    "steamgriddb": SteamGridDBSource,
    "mobygames": MobyGamesSource,
    "wikipedia": WikipediaSource,
    "wikidata": WikidataSource,
    "duckduckgo": DuckDuckGoSource,
    "bing": BingImagesSource,
}


def get_source(name: str, session=None) -> IconSource | None:
    """Get source instance by name."""
    cls = SOURCE_CLASSES.get(name.lower())
    if cls:
        return cls(session)
    return None


def get_all_sources(session=None, priority: list[str] | None = None) -> list[IconSource]:
    """Get all available sources in priority order."""
    priority = priority or SOURCE_PRIORITY
    sources = []
    for name in priority:
        src = get_source(name, session)
        if src:
            sources.append(src)
    return sources


def close_all(sources: list[IconSource]) -> None:
    """Close all source sessions."""
    for src in sources:
        src.close()