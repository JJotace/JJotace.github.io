import os
import json
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import psycopg2
from sentence_transformers import SentenceTransformer

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", 5432)),
    "dbname": os.getenv("DB_NAME", "smart_db"),
    "user": os.getenv("DB_USER", "smart_user"),
    "password": os.getenv("DB_PASS", "smart_pass"),
}

print("Loading embedding model...")
MODEL = SentenceTransformer("all-MiniLM-L6-v2")
print("Model ready.")


def get_connection():
    return psycopg2.connect(**DB_CONFIG)


class Handler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        print(f"[{self.address_string()}] {format % args}")

    def send_json(self, data, status=200):
        body = json.dumps(data).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", len(body))
        self.end_headers()
        self.wfile.write(body)

    def serve_file(self, path, content_type):
        try:
            with open(path, "rb") as f:
                body = f.read()
            self.send_response(200)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", len(body))
            self.end_headers()
            self.wfile.write(body)
        except FileNotFoundError:
            self.send_response(404)
            self.end_headers()

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path

        if path == "/" or path == "/index.html":
            self.serve_file("/app/frontend/index.html", "text/html")

        elif path == "/health":
            try:
                conn = get_connection()
                conn.close()
                self.send_json({"status": "ok"})
            except Exception as e:
                self.send_json({"status": "error", "detail": str(e)}, 500)

        elif path == "/search":
            params = parse_qs(parsed.query)
            query = params.get("q", [""])[0].strip()
            if not query:
                self.send_json({"error": "Missing query parameter 'q'"}, 400)
                return
            try:
                embedding = MODEL.encode(query).tolist()
                conn = get_connection()
                cur = conn.cursor()
                cur.execute(
                    """
                    SELECT c.id, c.name, c.number, c.rarity, s.name AS set_name,
                           c.vector <-> %s::vector AS distance,
                           MIN(i.price) AS min_price,
                           COALESCE(SUM(i.quantity), 0) AS total_stock,
                           c.image_url
                    FROM cards c
                    JOIN sets s ON c.set_id = s.id
                    LEFT JOIN inventory i ON i.card_id = c.id AND i.quantity > 0
                    GROUP BY c.id, c.name, c.number, c.rarity, s.name, c.vector, c.image_url
                    ORDER BY distance
                    LIMIT 10
                    """,
                    (embedding,),
                )
                rows = cur.fetchall()
                cur.close()
                conn.close()
                results = [
                    {"id": r[0], "name": r[1], "number": r[2], "rarity": r[3], "set": r[4], "distance": round(r[5], 4), "min_price": float(r[6]) if r[6] else None, "stock": int(r[7]), "image_url": r[8]}
                    for r in rows
                ]
                self.send_json({"query": query, "results": results})
            except Exception as e:
                self.send_json({"error": str(e)}, 500)

        elif path == "/search/like":
            params = parse_qs(parsed.query)
            query = params.get("q", [""])[0].strip()
            if not query:
                self.send_json({"error": "Missing query parameter 'q'"}, 400)
                return
            try:
                conn = get_connection()
                cur = conn.cursor()
                cur.execute(
                    """
                    SELECT c.id, c.name, c.number, c.rarity, s.name AS set_name,
                           MIN(i.price) AS min_price,
                           COALESCE(SUM(i.quantity), 0) AS total_stock,
                           c.image_url
                    FROM cards c
                    JOIN sets s ON c.set_id = s.id
                    LEFT JOIN inventory i ON i.card_id = c.id AND i.quantity > 0
                    WHERE c.name ILIKE %s
                       OR c.rarity ILIKE %s
                       OR s.name ILIKE %s
                    GROUP BY c.id, c.name, c.number, c.rarity, s.name, c.image_url
                    LIMIT 10
                    """,
                    (f"%{query}%", f"%{query}%", f"%{query}%"),
                )
                rows = cur.fetchall()
                cur.close()
                conn.close()
                results = [
                    {"id": r[0], "name": r[1], "number": r[2], "rarity": r[3], "set": r[4], "min_price": float(r[5]) if r[5] else None, "stock": int(r[6]), "image_url": r[7]}
                    for r in rows
                ]
                self.send_json({"query": query, "results": results})
            except Exception as e:
                self.send_json({"error": str(e)}, 500)

        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        parsed = urlparse(self.path)
        path = parsed.path

        if path == "/purchase":
            try:
                length = int(self.headers.get("Content-Length", 0))
                body = json.loads(self.rfile.read(length))
                customer_id    = body["customer_id"]
                inventory_id   = body["inventory_id"]
                quantity       = body["quantity"]
                payment_method = body["payment_method"]
            except (KeyError, json.JSONDecodeError) as e:
                self.send_json({"error": f"Invalid request body: {e}"}, 400)
                return
            try:
                conn = get_connection()
                cur = conn.cursor()
                cur.execute(
                    "CALL process_purchase(%s, %s, %s, %s::payment_method, NULL)",
                    (customer_id, inventory_id, quantity, payment_method),
                )
                order_id = cur.fetchone()[0]
                conn.commit()
                cur.close()
                conn.close()
                self.send_json({"status": "ok", "order_id": order_id})
            except Exception as e:
                self.send_json({"error": str(e)}, 500)

        else:
            self.send_response(404)
            self.end_headers()


if __name__ == "__main__":
    port = 8000
    print(f"Starting service on port {port}")
    HTTPServer(("0.0.0.0", port), Handler).serve_forever()