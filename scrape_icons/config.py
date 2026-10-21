#!/usr/bin/env python3
"""
Configuration constants for the game icon scraper.
"""

from pathlib import Path

# ─── Base Paths ──────────────────────────────────────────────────────────────
GAMES_ROOT = Path("/mnt/VG_00/PUBLIC-LIBRARY/GAMES/GAMES")
ICONS_ROOT = Path("/mnt/VG_00/PUBLIC-LIBRARY/PICTURES/ICONS/GAMEICONS")
EMU_ICONS_ROOT = ICONS_ROOT / "EMU-ICONS"
EMU_ICONS_INDEX = EMU_ICONS_ROOT / "_index.json"

# Working directories
WORK_DIR = Path(__file__).parent
TEMP_ICONS_DIR = WORK_DIR / "temp_icons"
INDEX_FILE = WORK_DIR / "games_index.json"
INDEX_BY_PATH_FILE = WORK_DIR / "games_index_by_path.json"
LOG_FILE = WORK_DIR / "scrape_log.json"
MANUAL_MAPPING_FILE = WORK_DIR / "manual_mapping.json"
ENV_FILE = WORK_DIR / ".env"

# ─── Skip Lists ──────────────────────────────────────────────────────────────
SKIP_PLATFORM_DIRS = {"WINDOWS", "LINUX", "COMMODORE"}

# ─── Platform Order (for display) ────────────────────────────────────────────
PLATFORM_ORDER = [
    "NINTENDO", "PLAYSTATION", "XBOX", "SEGA",
    "ATARI", "KONAMI", "NEOGEO", "MAME",
    "AMSTRADCPC", "MSX", "ARCADE",
    "ANDROID", "JAVA", "MAC",
]

# ─── Platform Title Mapping ──────────────────────────────────────────────────
PLATFORM_TITLES = {
    "NINTENDO": "Nintendo", "PLAYSTATION": "Sony / PlayStation",
    "XBOX": "Xbox", "SEGA": "Sega",
    "ATARI": "Atari", "KONAMI": "Konami",
    "NEOGEO": "Neo Geo", "MAME": "MAME",
    "AMSTRADCPC": "Amstrad CPC", "MSX": "MSX", "ARCADE": "Arcade",
    "ANDROID": "Android", "JAVA": "Java", "MAC": "Mac",
}

# ─── Folder Name → emulation.conf System Key Mapping ─────────────────────────
# Must match emulation.conf section names exactly (lowercase)
FOLDER_TO_EMU_SYSTEM = {
    # PlayStation
    "PSX": "psx", "PS2": "ps2", "PS3": "ps3", "PSP": "psp",
    # Nintendo
    "SNES": "snes", "NES": "nes", "N64": "n64", "GB": "gb",
    "GBC": "gbc", "GBA": "gba", "NDS": "nds", "3DS": "3ds",
    "WII": "wii", "FAMICOM": "famicom",
    # Sega
    "MEGADRIVE": "megadrive", "MASTERSYSTEM": "mastersystem", "GAMEGEAR": "gamegear",
    # Atari
    "ATARI2600": "atari2600", "ATARI7800": "atari7800", "ATARILYNX": "atarilynx",
    # Konami / TurboGrafx
    "TURBOGRAFX": "turbogrfx",
    # NeoGeo
    "NEOGEO": "neogeo",
    # MAME
    "MAME": "mame",
    # Commodore
    "C64": "c64", "C128": "c128", "VIC20": "vic20", "AMIGA": "amiga",
    # Amstrad / MSX / Arcade
    "AMSTRADCPC": "amstradcpc", "MSX": "msx", "ARCADE": "arcade",
    # Xbox
    "XBOX": "xbox",
    # Android / Java / Mac (no emu config typically, but keep for structure)
    "ANDROID": "android", "JAVA": "java", "MAC": "mac",
}

# Reverse mapping for lookup
EMU_SYSTEM_TO_FOLDER = {v: k for k, v in FOLDER_TO_EMU_SYSTEM.items()}

# ─── System Aliases (from game-gui-fork.py _SYSTEM_ALIASES) ──────────────────
SYSTEM_ALIASES = {
    "turbografx": "turbogrfx",
}

# ─── Scraping Settings ───────────────────────────────────────────────────────
DEFAULT_WORKERS = 3
DEFAULT_DELAY = 1.5  # seconds between requests per worker
MIN_ICON_WIDTH = 256
MIN_ICON_HEIGHT = 256
MAX_ASPECT_RATIO = 2.0  # width/height max
MIN_ASPECT_RATIO = 0.5  # width/height min

# ─── API Key Defaults (overridden by .env) ───────────────────────────────────
IGDB_CLIENT_ID = ""
IGDB_CLIENT_SECRET = ""
STEAMGRIDDB_API_KEY = ""

# ─── Source Priority (fallback chain) ────────────────────────────────────────
# Wikipedia and DuckDuckGo are faster (no API key needed, less rate limiting)
SOURCE_PRIORITY = ["wikipedia", "duckduckgo", "bing", "mobygames", "igdb", "steamgriddb"]

# ─── Supported Image Extensions ──────────────────────────────────────────────
IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp"}

# ─── Junk Extensions/Names to Ignore When Scanning ───────────────────────────
JUNK_EXTS = {".sh", ".txt", ".nfo", ".diz", ".md", ".sfv", ".jpg", ".jpeg",
             ".png", ".gif", ".bmp", ".xml", ".json", ".log", ".ini", ".cfg"}
JUNK_NAMES = {"file_id.diz", "readme.txt", "readme.md", "readme"}

# ─── Bucket Threshold (from game-gui-fork.py) ────────────────────────────────
BUCKET_THRESHOLD = 500

# ─── Regex for Prettifying Names (from game-gui-fork.py) ─────────────────────
import re
PRETTIFY_SPLIT_RE = re.compile(r"[-_]")
CAMEL_CASE_RE = re.compile(r"([a-z])([A-Z])")