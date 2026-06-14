"""
sync_prices.py — Fetch real market prices and card images from TCG Price
Lookup API and update inventory via the bulk_price_update stored procedure.
Also stores image_url on the cards table for use in the search frontend.

Targets high-rarity cards only (SIR, MAR, MHR) by default to stay well
within the 200 req/day API limit (~62 requests per full run).
Prices are stored in USD as received from the TCGPlayer API.

Usage:
    python sync_prices.py [--dry-run] [--rarity IR UR SIR MAR MHR]

    --dry-run   Fetch prices and print them without writing to the DB.
    --rarity    Space-separated rarities to sync (default: SIR MAR MHR).

Examples:
    python sync_prices.py                          # sync SIR/MAR/MHR (62 req)
    python sync_prices.py --rarity MHR MAR         # only the rarest (17 req)
    python sync_prices.py --dry-run                # preview without DB writes
    python sync_prices.py --rarity IR UR SIR MAR MHR  # full sync (200 req)
"""

import os
import csv
import time
import argparse
import urllib.request
import urllib.parse
import json
import psycopg2

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

API_KEY  = os.getenv("TCG_API_KEY", "tcg_d5ad521b32db0bf270944d33d213213bcb31c5034e59fb4b")
API_BASE = "https://api.tcgpricelookup.com/v1"

DB_CONFIG = {
    "host":     os.getenv("DB_HOST",  "localhost"),
    "port":     int(os.getenv("DB_PORT", 5432)),
    "dbname":   os.getenv("DB_NAME",  "smart_db"),
    "user":     os.getenv("DB_USER",  "smart_user"),
    "password": os.getenv("DB_PASS",  "smart_pass"),
}

CONDITION_MULTIPLIERS = {
    "mint":      1.00,
    "near_mint": 0.85,
    "excellent": 0.65,
    "good":      0.45,
    "played":    0.25,
    "poor":      0.10,
}

# ---------------------------------------------------------------------------
# API helpers
# ---------------------------------------------------------------------------

def api_get(path: str, params: dict) -> dict:
    url = f"{API_BASE}{path}?{urllib.parse.urlencode(params)}"
    req = urllib.request.Request(url, headers={"X-API-Key": API_KEY, "User-Agent": "curl/8.5.0", "Accept": "*/*"})
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read())


def fetch_card_data(card_name: str, number: str) -> tuple[float | None, str | None]:
    """
    Search for a card by name and number.
    Returns (near_mint_usd_price, image_url) — either may be None.

    The API appends the card number to the name: "Mega Gardevoir ex - 187/132".
    We reconstruct this exact string and match precisely, which is unambiguous.
    """
    api_name = f"{card_name} - {number}"
    params = {
        "q":     card_name,
        "game":  "pokemon",
        "limit": 50,
    }
    try:
        data = api_get("/cards/search", params)
    except Exception as e:
        print(f"    API error for '{card_name}': {e}")
        return None, None

    results = data.get("data", [])
    for card in results:
        if card.get("name", "").lower() == api_name.lower():
            return _extract_price(card), card.get("image_url")

    return None, None


def _extract_price(card: dict) -> float | None:
    try:
        return card["prices"]["raw"]["near_mint"]["tcgplayer"]["market"]
    except (KeyError, TypeError):
        pass
    try:
        return card["prices"]["raw"]["near_mint"]["ebay"]["avg_7d"]
    except (KeyError, TypeError):
        pass
    return None


# ---------------------------------------------------------------------------
# Database helpers
# ---------------------------------------------------------------------------

def load_inventory(conn, card_ids: set) -> dict:
    cur = conn.cursor()
    cur.execute(
        """
        SELECT id, card_id, condition, price
        FROM inventory
        WHERE card_id = ANY(%s)
        ORDER BY card_id, condition
        """,
        (list(card_ids),),
    )
    rows = cur.fetchall()
    cur.close()
    result = {}
    for inv_id, card_id, condition, price in rows:
        result.setdefault(card_id, []).append((inv_id, condition, float(price)))
    return result


def apply_prices(conn, updates: list, dry_run: bool) -> int:
    if not updates:
        return 0
    if dry_run:
        for inv_id, price in updates:
            print(f"      [dry-run] inventory_id={inv_id} → ${price:.2f}")
        return len(updates)
    cur = conn.cursor()
    array_literal = "ARRAY[" + ",".join(
        f"ROW({inv_id}, {price:.2f})::price_update_input"
        for inv_id, price in updates
    ) + "]"
    cur.execute(f"CALL bulk_price_update({array_literal})")
    conn.commit()
    cur.close()
    return len(updates)


def apply_image_urls(conn, image_updates: list, dry_run: bool) -> int:
    """Write image_url back to cards table for matched cards."""
    if not image_updates or dry_run:
        if dry_run:
            for card_id, url in image_updates:
                print(f"      [dry-run] cards.id={card_id} image_url={url}")
        return len(image_updates)
    cur = conn.cursor()
    cur.executemany(
        "UPDATE cards SET image_url = %s WHERE id = %s",
        [(url, card_id) for card_id, url in image_updates],
    )
    conn.commit()
    cur.close()
    return len(image_updates)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Sync TCG market prices and images into Smart DB.")
    parser.add_argument("--dry-run", action="store_true",
                        help="Fetch data but do not write to DB.")
    parser.add_argument("--rarity", nargs="+",
                        default=["Special Illustration Rare", "Mega Attack Rare", "Mega Hyper Rare"],
                        help="Rarities to sync.")
    args = parser.parse_args()

    target_rarities = set(args.rarity)

    print("=" * 60)
    print("Smart DB — TCG Price & Image Sync")
    print(f"Rarities : {', '.join(sorted(target_rarities))}")
    print(f"Dry run  : {args.dry_run}")
    print("=" * 60)

    # Locate CSV files
    base = os.path.dirname(__file__)
    sets_path  = os.path.join(base, "data", "sets.csv")
    cards_path = os.path.join(base, "data", "cards.csv")

    sets = {}
    with open(sets_path) as f:
        for row in csv.DictReader(f):
            sets[int(row["id"])] = row["name"]

    cards = []
    with open(cards_path) as f:
        for row in csv.DictReader(f):
            if row["rarity"] in target_rarities:
                cards.append({
                    "id":       int(row["id"]),
                    "name":     row["name"],
                    "number":   row["number"],
                    "rarity":   row["rarity"],
                    "set_name": sets[int(row["set_id"])],
                })

    # Deduplicate by name+rarity — same card name at different rarities
    # has different artwork and must be fetched separately
    seen: dict[tuple, dict] = {}
    for card in cards:
        key = (card["name"], card["number"])
        if key not in seen:
            seen[key] = card
    unique_cards = list(seen.values())

    print(f"\nCards to sync : {len(cards)} ({len(unique_cards)} unique names, ~{len(unique_cards)} API requests)\n")

    # Fetch from API
    fetched_prices: dict[str, float] = {}
    fetched_images: dict[str, str]   = {}
    not_found = []

    for i, card in enumerate(unique_cards, 1):
        print(f"  [{i:3}/{len(unique_cards)}] {card['name'][:45]:<45} ", end="", flush=True)
        price, image_url = fetch_card_data(card["name"], card["number"])
        parts = []
        if price:
            fetched_prices[card["name"]] = price
            parts.append(f"${price:.2f}")
        if image_url:
            fetched_images[(card["name"], card["number"])] = image_url
            parts.append("img ✓")
        if parts:
            print(" | ".join(parts))
        else:
            not_found.append(card["name"])
            print("not found")

        if i < len(unique_cards):
            time.sleep(3)

    print(f"Prices found   : {len(fetched_prices)}")
    print(f"Images found   : {len(fetched_images)}")
    print(f"Not found      : {len(not_found)}")

    if not fetched_prices and not fetched_images:
        print("\nNothing to update.")
        return

    conn = None if args.dry_run else psycopg2.connect(**DB_CONFIG)
    read_conn = conn or psycopg2.connect(**DB_CONFIG)

    card_ids = {c["id"] for c in cards}
    inventory = load_inventory(read_conn, card_ids)

    # --- Price updates ---
    price_updates = []
    skipped = 0

    for card in cards:
        nm_price = fetched_prices.get(card["name"])
        if nm_price is None:
            continue
        for inv_id, condition, current_price in inventory.get(card["id"], []):
            new_price = max(round(nm_price * CONDITION_MULTIPLIERS.get(condition, 1.0), 2), 0.01)
            if abs(new_price - current_price) < 0.01:
                skipped += 1
                continue
            price_updates.append((inv_id, new_price))

    # --- Image updates ---
    # One image_url per card id — use the first card in CSV that matched
    image_updates = []
    seen_card_ids = set()
    for card in cards:
        if card["id"] in seen_card_ids:
            continue
        url = fetched_images.get((card["name"], card["number"]))
        if url:
            image_updates.append((card["id"], url))
            seen_card_ids.add(card["id"])

    print(f"\nInventory entries to update : {len(price_updates)}")
    print(f"Unchanged (skipped)         : {skipped}")
    print(f"Card images to store        : {len(image_updates)}")

    updated_prices = apply_prices(conn, price_updates, args.dry_run)
    updated_images = apply_image_urls(conn, image_updates, args.dry_run)

    if not args.dry_run:
        print(f"\nDone.")
        print(f"  Prices updated : {updated_prices} USD (logged in price_history via trigger)")
        print(f"  Images stored  : {updated_images}")

    if conn:
        conn.close()
    if read_conn and read_conn is not conn:
        read_conn.close()



if __name__ == "__main__":
    main()