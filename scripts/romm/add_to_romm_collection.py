#!/usr/bin/env python3
"""
Script to add GBA games from list.txt to a Romm collection.
"""

import urllib.request
import urllib.parse
import urllib.error
import http.client
import re
import json
import base64
import unicodedata
from typing import List, Dict, Optional

# Configuration
ROMM_URL = "http://localhost:8091"
COLLECTION_NAME = "Top GBA Games"

class RommClient:
    def __init__(self, base_url: str, username: str, password: str):
        self.base_url = base_url.rstrip('/')
        self.username = username
        self.password = password
        self.token = None

    def _make_request(self, path: str, method: str = "GET", data: bytes = None, params: dict = None, content_type: str = None) -> Optional[dict]:
        """Make an HTTP request to the Romm API."""
        if params:
            query_string = urllib.parse.urlencode(params)
            url = f"{self.base_url}{path}?{query_string}"
        else:
            url = f"{self.base_url}{path}"

        req = urllib.request.Request(url, data=data, method=method)

        if self.token:
            req.add_header("Authorization", f"Bearer {self.token}")

        if content_type:
            req.add_header("Content-Type", content_type)

        try:
            with urllib.request.urlopen(req) as response:
                response_data = response.read().decode('utf-8')
                if response_data:
                    return json.loads(response_data)
                return {}
        except urllib.error.HTTPError as e:
            error_body = e.read().decode('utf-8')
            print(f"HTTP Error {e.code}: {error_body}")
            return None
        except Exception as e:
            print(f"Request failed: {e}")
            return None

    def login(self) -> bool:
        """Authenticate with Romm using OAuth2."""
        # Request necessary scopes
        scopes = "platforms.read roms.read collections.read collections.write"
        data = urllib.parse.urlencode({
            "username": self.username,
            "password": self.password,
            "grant_type": "password",
            "scope": scopes
        }).encode('utf-8')

        url = f"{self.base_url}/api/token"
        req = urllib.request.Request(url, data=data, method="POST")
        req.add_header("Content-Type", "application/x-www-form-urlencoded")

        try:
            with urllib.request.urlopen(req) as response:
                result = json.loads(response.read().decode('utf-8'))
                if result and "access_token" in result:
                    self.token = result["access_token"]
                    print(f"✓ Successfully authenticated as {self.username}")
                    return True
        except urllib.error.HTTPError as e:
            error_body = e.read().decode('utf-8')
            print(f"✗ Authentication failed: HTTP {e.code}")
            print(f"  Response: {error_body}")
            return False
        except Exception as e:
            print(f"✗ Authentication failed: {e}")
            return False

        print("✗ Authentication failed")
        return False

    def get_all_roms(self, platform_id: Optional[int] = None) -> List[Dict]:
        """Get all ROMs, optionally filtered by platform."""
        all_roms = []
        limit = 500
        offset = 0

        while True:
            params = {"limit": limit, "offset": offset}
            if platform_id:
                params["platform_id"] = platform_id

            result = self._make_request("/api/roms", params=params)
            if not result or "items" not in result:
                break

            roms = result["items"]
            if not roms:
                break

            all_roms.extend(roms)

            # Check if we got all of them
            total = result.get("total", len(all_roms))
            if len(all_roms) >= total:
                break

            offset += limit

        print(f"✓ Found {len(all_roms)} ROMs")
        return all_roms

    def get_platforms(self) -> List[Dict]:
        """Get all platforms."""
        result = self._make_request("/api/platforms")
        if result:
            print(f"✓ Found {len(result)} platforms")
            return result
        else:
            print("✗ Failed to get platforms")
            return []

    def get_collections(self) -> List[Dict]:
        """Get all collections."""
        result = self._make_request("/api/collections")
        if result:
            print(f"✓ Found {len(result)} collections")
            return result
        else:
            print("✗ Failed to get collections")
            return []

    def create_collection(self, name: str, description: str, rom_ids: List[int], is_public: bool = False) -> Optional[Dict]:
        """Create a new collection with the given ROMs."""
        # Build multipart form data
        boundary = '----WebKitFormBoundary' + ''.join([str(ord(c) % 10) for c in name[:16]])
        parts = []

        # Add name field
        parts.append(f'--{boundary}')
        parts.append('Content-Disposition: form-data; name="name"')
        parts.append('')
        parts.append(name)

        # Add description field
        parts.append(f'--{boundary}')
        parts.append('Content-Disposition: form-data; name="description"')
        parts.append('')
        parts.append(description)

        # Add rom_ids field
        parts.append(f'--{boundary}')
        parts.append('Content-Disposition: form-data; name="rom_ids"')
        parts.append('')
        parts.append(json.dumps(rom_ids))

        parts.append(f'--{boundary}--')
        parts.append('')

        body = '\r\n'.join(parts).encode('utf-8')

        params = {"is_public": "true" if is_public else "false"}

        # Make request
        url = f"{self.base_url}/api/collections?{urllib.parse.urlencode(params)}"
        req = urllib.request.Request(url, data=body, method="POST")
        req.add_header("Authorization", f"Bearer {self.token}")
        req.add_header("Content-Type", f"multipart/form-data; boundary={boundary}")

        try:
            with urllib.request.urlopen(req) as response:
                result = json.loads(response.read().decode('utf-8'))
                print(f"✓ Created collection '{name}' with {len(rom_ids)} ROMs")
                return result
        except urllib.error.HTTPError as e:
            error_body = e.read().decode('utf-8')
            print(f"✗ Failed to create collection: HTTP {e.code}")
            print(f"  Response: {error_body}")
            return None
        except Exception as e:
            print(f"✗ Failed to create collection: {e}")
            return None

    def update_collection(self, collection_id: int, name: str, description: str, rom_ids: List[int]) -> Optional[Dict]:
        """Update a collection with new ROM IDs."""
        # Build multipart form data
        boundary = '----WebKitFormBoundary' + str(collection_id).zfill(16)
        parts = []

        # Add name field
        parts.append(f'--{boundary}')
        parts.append('Content-Disposition: form-data; name="name"')
        parts.append('')
        parts.append(name)

        # Add description field
        parts.append(f'--{boundary}')
        parts.append('Content-Disposition: form-data; name="description"')
        parts.append('')
        parts.append(description)

        # Add rom_ids field
        parts.append(f'--{boundary}')
        parts.append('Content-Disposition: form-data; name="rom_ids"')
        parts.append('')
        parts.append(json.dumps(rom_ids))

        parts.append(f'--{boundary}--')
        parts.append('')

        body = '\r\n'.join(parts).encode('utf-8')

        # Make request
        url = f"{self.base_url}/api/collections/{collection_id}"
        req = urllib.request.Request(url, data=body, method="PUT")
        req.add_header("Authorization", f"Bearer {self.token}")
        req.add_header("Content-Type", f"multipart/form-data; boundary={boundary}")

        try:
            with urllib.request.urlopen(req) as response:
                result = json.loads(response.read().decode('utf-8'))
                print(f"✓ Updated collection with {len(rom_ids)} ROMs")
                return result
        except urllib.error.HTTPError as e:
            error_body = e.read().decode('utf-8')
            print(f"✗ Failed to update collection: HTTP {e.code}")
            print(f"  Response: {error_body}")
            return None
        except Exception as e:
            print(f"✗ Failed to update collection: {e}")
            return None


def parse_game_list(filename: str) -> List[str]:
    """Parse the game list file and extract game names."""
    games = []
    with open(filename, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            # Extract game name from format like "1. Metroid Fusion - 167 (2)"
            match = re.match(r'^\d+\.?\s+(.+?)\s+-\s+\d+', line)
            if match:
                game_name = match.group(1).strip()
                games.append(game_name)

    return games


def normalize_name(name: str) -> str:
    """Normalize a game name for comparison."""
    # Normalize Unicode characters (é -> e, etc.)
    name = unicodedata.normalize('NFKD', name)
    name = ''.join([c for c in name if not unicodedata.combining(c)])

    # Remove file extensions first
    name = re.sub(r'\.(gba|gb|gbc|nes|snes|sfc|n64|z64|nds)$', '', name, flags=re.IGNORECASE)

    # Remove common suffixes and region tags
    name = name.lower()
    name = re.sub(r'\s*\(.*?\)\s*', '', name)  # Remove parentheses (USA, Europe, etc.)
    name = re.sub(r'\s*\[.*?\]\s*', '', name)  # Remove brackets

    # Remove common punctuation but preserve spaces
    name = re.sub(r'[,:\-]', ' ', name)  # Convert punctuation to spaces
    name = re.sub(r'[^\w\s]', '', name)  # Remove remaining special chars

    # Normalize whitespace
    name = re.sub(r'\s+', ' ', name).strip()

    # Remove common articles at the beginning or end
    name = re.sub(r'\bthe\b\s*$', '', name).strip()  # Remove "the" at end
    name = re.sub(r'^\s*the\b', '', name).strip()  # Remove "the" at beginning

    return name


def get_tokens(name: str) -> set:
    """Get word tokens from a normalized name."""
    normalized = normalize_name(name)
    # Split into words and filter out very short words
    tokens = set(word for word in normalized.split() if len(word) > 2)
    return tokens


def calculate_match_score(game_name: str, rom_name: str) -> float:
    """Calculate similarity score between two names based on token overlap."""
    game_tokens = get_tokens(game_name)
    rom_tokens = get_tokens(rom_name)

    if not game_tokens or not rom_tokens:
        return 0.0

    # Calculate Jaccard similarity (intersection over union)
    intersection = len(game_tokens & rom_tokens)
    union = len(game_tokens | rom_tokens)

    return intersection / union if union > 0 else 0.0


def match_games_to_roms(games: List[str], roms: List[Dict], debug: bool = False) -> Dict[str, Optional[int]]:
    """Match game names to ROM IDs using fuzzy token-based matching."""
    matches = {}

    # Build list of ROMs with their names
    rom_list = []
    for rom in roms:
        # Try name first (from metadata), fallback to filesystem name
        rom_name = rom.get('name') or rom.get('fs_name_no_ext', '')
        if rom_name:
            rom_list.append({
                'id': rom['id'],
                'name': rom_name,
                'fs_name': rom.get('fs_name_no_ext', '')
            })

    # Match each game
    for game in games:
        normalized_game = normalize_name(game)

        # Try exact normalized match first
        best_match = None
        best_score = 0.0

        for rom in rom_list:
            normalized_rom = normalize_name(rom['name'])

            # Exact match
            if normalized_game == normalized_rom:
                best_match = rom['id']
                best_score = 1.0
                break

            # Substring match
            if normalized_game in normalized_rom or normalized_rom in normalized_game:
                score = 0.9
                if score > best_score:
                    best_score = score
                    best_match = rom['id']

        # If no exact/substring match, try token-based fuzzy matching
        if best_score < 0.9:
            for rom in rom_list:
                score = calculate_match_score(game, rom['name'])

                # Require at least 60% token overlap
                if score >= 0.6 and score > best_score:
                    best_score = score
                    best_match = rom['id']

        if best_match:
            matches[game] = best_match
        else:
            matches[game] = None
            print(f"⚠ Could not match: {game}")

            # Debug: show top 3 candidates if debug mode
            if debug and 'pokemon' in game.lower():
                candidates = []
                for rom in rom_list:
                    if 'pokemon' in rom['name'].lower() or 'pokemon' in rom.get('fs_name', '').lower():
                        score = calculate_match_score(game, rom['name'])
                        candidates.append((score, rom['name'], rom.get('fs_name', '')))

                candidates.sort(reverse=True)
                print(f"  Top Pokemon ROMs:")
                for score, name, fs_name in candidates[:3]:
                    print(f"    {score:.2%} - {name}")
                    if fs_name and fs_name != name:
                        print(f"           (fs: {fs_name})")

    return matches


def main():
    import sys
    import getpass

    print("=" * 60)
    print("Romm Collection Manager - Top GBA Games")
    print("=" * 60)
    print()

    # Get credentials from command line, env var, or prompt
    import os
    if len(sys.argv) >= 3:
        username = sys.argv[1]
        password = sys.argv[2]
        print(f"Using credentials from command line")
    elif 'ROMM_USER' in os.environ and 'ROMM_PASS' in os.environ:
        username = os.environ['ROMM_USER']
        password = os.environ['ROMM_PASS']
        print(f"Using credentials from environment variables")
    else:
        username = input("Romm username: ")
        password = getpass.getpass("Romm password: ")

    # Create client and login
    client = RommClient(ROMM_URL, username, password)
    if not client.login():
        print("\n✗ Failed to authenticate. Exiting.")
        return 1

    print()

    # Get GBA platform ID
    platforms = client.get_platforms()
    gba_platform = None
    for platform in platforms:
        if 'gba' in platform.get('slug', '').lower() or 'game boy advance' in platform.get('name', '').lower():
            gba_platform = platform
            print(f"✓ Found GBA platform: {platform.get('name')} (ID: {platform['id']})")
            break

    if not gba_platform:
        print("✗ Could not find GBA platform")
        return 1

    print()

    # Get all GBA ROMs
    print("Fetching GBA ROMs...")
    roms = client.get_all_roms(platform_id=gba_platform['id'])
    if not roms:
        print("✗ No ROMs found")
        return 1

    print()

    # Parse game list
    print("Parsing game list...")
    games = parse_game_list('list.txt')
    print(f"✓ Found {len(games)} games in list.txt")
    print()

    # Match games to ROMs
    print("Matching games to ROMs...")
    import os
    debug_mode = os.environ.get('DEBUG', '').lower() in ('1', 'true', 'yes')
    matches = match_games_to_roms(games, roms, debug=debug_mode)
    matched_rom_ids = [rom_id for rom_id in matches.values() if rom_id is not None]

    print(f"✓ Matched {len(matched_rom_ids)} out of {len(games)} games")
    print()

    # Check if collection exists
    collections = client.get_collections()
    existing_collection = None
    for collection in collections:
        if collection['name'].lower() == COLLECTION_NAME.lower():
            existing_collection = collection
            break

    # Create or update collection
    description = f"Top {len(games)} GBA games collection"
    if existing_collection:
        print(f"Collection '{COLLECTION_NAME}' already exists (ID: {existing_collection['id']})")
        # Auto-confirm if running non-interactively
        import sys
        if len(sys.argv) >= 3 or ('ROMM_USER' in os.environ and 'ROMM_PASS' in os.environ):
            update = 'y'
            print("Auto-updating collection...")
        else:
            update = input("Do you want to update it? (y/n): ")
        if update.lower() == 'y':
            result = client.update_collection(
                existing_collection['id'],
                COLLECTION_NAME,
                description,
                matched_rom_ids
            )
            if result:
                print(f"\n✓ Successfully updated collection!")
                print(f"  Collection now has {len(matched_rom_ids)} games")
        else:
            print("Skipped update")
    else:
        print(f"Creating new collection '{COLLECTION_NAME}'...")
        result = client.create_collection(COLLECTION_NAME, description, matched_rom_ids, is_public=False)
        if result:
            print(f"\n✓ Successfully created collection!")
            print(f"  Collection ID: {result['id']}")
            print(f"  Games added: {len(matched_rom_ids)}")

    # Show unmatched games
    unmatched = [game for game, rom_id in matches.items() if rom_id is None]
    if unmatched:
        print(f"\n⚠ {len(unmatched)} games could not be matched:")
        for game in unmatched[:10]:  # Show first 10
            print(f"  - {game}")
        if len(unmatched) > 10:
            print(f"  ... and {len(unmatched) - 10} more")

    print("\n" + "=" * 60)
    print("Done!")
    print("=" * 60)

    return 0


if __name__ == "__main__":
    exit(main())
