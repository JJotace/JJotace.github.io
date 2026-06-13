import os
import csv
import psycopg2
from sentence_transformers import SentenceTransformer

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", 5432)),
    "dbname": os.getenv("DB_NAME", "smart_db"),
    "user": os.getenv("DB_USER", "smart_user"),
    "password": os.getenv("DB_PASS", "smart_pass"),
}

SETS_CSV  = os.getenv("SETS_CSV",  "/app/data/sets.csv")
CARDS_CSV = os.getenv("CARDS_CSV", "/app/data/cards.csv")


def load_sets(path):
    sets = {}
    with open(path, newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            sets[int(row["id"])] = {
                "name":         row["name"],
                "release_date": row["release_date"],
            }
    return sets


def load_cards(path):
    cards = []
    with open(path, newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            cards.append({
                "id":     int(row["id"]),
                "name":   row["name"],
                "number": row["number"],
                "rarity": row["rarity"],
                "set_id": int(row["set_id"]),
            })
    return cards


def main():
    print("Loading model...")
    model = SentenceTransformer("all-MiniLM-L6-v2")

    print("Reading CSV files...")
    sets  = load_sets(SETS_CSV)
    cards = load_cards(CARDS_CSV)

    print(f"Generating embeddings for {len(cards)} cards...")
    texts = [
        f"{c['name']} {c['rarity']} {sets[c['set_id']]['name']}"
        for c in cards
    ]
    embeddings = model.encode(texts, show_progress_bar=True)

    print("Inserting into database...")
    conn = psycopg2.connect(**DB_CONFIG)
    cur  = conn.cursor()

    for set_id, s in sets.items():
        cur.execute(
            """
            INSERT INTO sets (id, name, release_date)
            VALUES (%s, %s, %s)
            ON CONFLICT (id) DO NOTHING
            """,
            (set_id, s["name"], s["release_date"]),
        )

    for card, embedding in zip(cards, embeddings):
        cur.execute(
            """
            INSERT INTO cards (id, name, number, rarity, set_id, vector)
            VALUES (%s, %s, %s, %s, %s, %s)
            ON CONFLICT (id) DO UPDATE SET vector = EXCLUDED.vector
            """,
            (
                card["id"],
                card["name"],
                card["number"],
                card["rarity"],
                card["set_id"],
                embedding.tolist(),
            ),
        )

    conn.commit()
    cur.close()
    conn.close()
    print(f"Done — {len(cards)} cards imported with embeddings.")


if __name__ == "__main__":
    main()