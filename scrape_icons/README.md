# Game Icon Scraper

Standalone utility to scrape game icons from multiple sources and organize them in a structured directory matching the `GAMES/GAMES` layout.

## Features

- **Multi-source scraping**: IGDB, SteamGridDB, MobyGames, Wikipedia/Wikidata (fallback chain)
- **Smart matching**: Fuzzy matching + manual overrides for messy folder names
- **Structured output**: Mirrors `GAMES/GAMES` directory structure in `EMU-ICONS/`
- **JSON index**: Maps folder paths to metadata for launcher integration
- **Resumable**: Can resume interrupted scrapes
- **Parallel downloads**: Configurable workers with rate limiting

## Directory Structure

```
scrape_icons/
├── main.py                 # CLI entry point
├── config.py               # Paths, mappings, constants
├── scanner.py              # Phase 1: Directory scanning
├── scraper.py              # Phase 2: Icon scraping
├── placer.py               # Phase 3: Move to final location
├── verify.py               # Phase 4: Validation
├── matching.py             # Fuzzy matching + manual overrides
├── sources/
│   ├── __init__.py         # Source registry
│   ├── base.py             # Abstract base class
│   ├── igdb.py             # IGDB API (requires keys)
│   ├── steamgriddb.py      # SteamGridDB API (requires key)
│   ├── mobygames.py        # MobyGames HTML scraping
│   └── wikipedia.py        # Wikipedia/Wikidata API
├── manual_mapping.json     # Folder name → search term overrides
├── .env.template           # API keys template
├── requirements.txt
└── README.md
```

## Installation

```bash
cd /mnt/VG_00/PUBLIC-LIBRARY/PRE-INSTALLED-GAMES/WINEPREFIX/scrape_icons
pip install -r requirements.txt
cp .env.template .env
# Edit .env and add your API keys
```

## API Keys

| Source | Required | Where to Get |
|--------|----------|--------------|
| IGDB | Yes (best quality) | https://dev.twitch.tv/console/apps |
| SteamGridDB | Yes (good covers) | https://www.steamgriddb.com/profile/preferences/api |
| MobyGames | No | N/A (HTML scraping) |
| Wikipedia | No | N/A (public API) |

Edit `.env`:
```env
IGDB_CLIENT_ID=your_client_id
IGDB_CLIENT_SECRET=your_client_secret
STEAMGRIDDB_API_KEY=your_api_key
```

## Usage

### Phase 1: Scan (build index)
```bash
# Dry run to see what would be indexed
python3 -m scrape_icons scan --dry-run

# Full scan
python3 -m scrape_icons scan

# Scan only specific platforms
python3 -m scrape_icons scan --only-platforms NINTENDO,SEGA
```

### Phase 2: Scrape (download icons)
```bash
# Scrape all (resume if interrupted)
python3 -m scrape_icons scrape --resume

# Custom workers/delay
python3 -m scrape_icons scrape --workers 3 --delay 1.5

# Skip if temp icon already exists
python3 -m scrape_icons scrape --skip-existing
```

### Phase 3: Place (move to final location)
```bash
# Move temp icons to EMU-ICONS
python3 -m scrape_icons place

# Force overwrite existing
python3 -m scrape_icons place --force

# Skip if final icon exists
python3 -m scrape_icons place --skip-existing
```

### Phase 4: Verify
```bash
# Check all icons
python3 -m scrape_icons verify

# Generate missing list for manual fixing
python3 -m scrape_icons verify --fix-missing
```

### Run All Phases
```bash
# Complete pipeline
python3 -m scrape_icons run

# With custom settings
python3 -m scrape_icons run --workers 3 --delay 1.5 --only-platforms NINTENDO,SEGA
```

## Manual Mapping

For games with messy folder names, edit `manual_mapping.json`:

```json
{
  "GTA V Build 2802-Online 1_64 met alle DLC_s - Werkt OK": "Grand Theft Auto V",
  "The.Last.of.Us.Part.II.Remastered": "The Last of Us Part II"
}
```

The scraper checks this first before trying other search terms.

## Output Structure

```
/mnt/VG_00/PUBLIC-LIBRARY/PICTURES/ICONS/GAMEICONS/
├── EMU-ICONS/
│   ├── NINTENDO/
│   │   ├── SNES/
│   │   │   ├── Chrono Trigger.png
│   │   │   └── Super Mario World.png
│   │   └── ...
│   ├── PLAYSTATION/
│   │   ├── PSX/
│   │   └── ...
│   └── ...
├── games_index.json          # Main index (key = relative path)
├── games_index_by_path.json  # Lookup by absolute folder path
└── scrape_log.json           # Audit trail
```

## Index Format

`games_index.json`:
```json
{
  "NINTENDO/SNES/Chrono Trigger": {
    "platform": "NINTENDO",
    "system": "snes",
    "system_folder": "SNES",
    "folder_name": "Chrono Trigger",
    "display_name": "Chrono Trigger",
    "icon_rel_path": "NINTENDO/SNES/Chrono Trigger.png",
    "icon_abs_path": "/mnt/VG_00/PUBLIC-LIBRARY/PICTURES/ICONS/GAMEICONS/EMU-ICONS/NINTENDO/SNES/Chrono Trigger.png",
    "search_terms": ["Chrono Trigger", "Chrono Trigger snes", ...],
    "source": "igdb",
    "matched_name": "Chrono Trigger",
    "scraped_at": "2026-10-19T14:30:00Z",
    "status": "placed"
  }
}
```

## Status Values

- `pending` - Not yet scraped
- `ok` - Scraped successfully, in temp
- `placed` - Moved to final location
- `skipped` - Already existed
- `failed` - All sources failed
- `missing_temp` - Temp file missing during place
- `place_failed` - Error moving file

## Skipped Platforms

By default, these platforms are **not scanned** (per game-gui-fork.py config):
- `WINDOWS`
- `LINUX`
- `COMMODORE`

## System Key Mapping

Folder names are mapped to `emulation.conf` system keys:
- `SNES` → `snes`
- `PSX` → `psx`
- `MEGADRIVE` → `megadrive`
- `TURBOGRAFX` → `turbogrfx`
- etc. (see `config.py:FOLDER_TO_EMU_SYSTEM`)

## Troubleshooting

### No icons found for a game
1. Check `manual_mapping.json` - add an override
2. Check `scrape_log.json` for errors
3. Try running with `--workers 1 --delay 3` for debugging

### Rate limited
- Increase `--delay` (default 1.5s)
- Reduce `--workers` (default 3)

### Corrupt images
Run `verify --fix-missing` to generate a list, then manually download/replace.

## License

MIT - Use freely for personal game library management.