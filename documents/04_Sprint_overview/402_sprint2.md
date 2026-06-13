---
layout: default
title: 4.2 Sprint 2 — Realization
parent: 4. Sprint Overview
nav_order: 2
---

# Sprint 2 — Realization

Burndown Chart

## Sprint Planning

### Backlog for this Sprint

| 2.1 | Docker Compose Setup | 2 | 3 | Must |
| 2.2 | PostgreSQL Schema Implementation | 2 | 5 | Must |
| 2.3 | Database Abstractions (Triggers, SPs, Functions) | 2 | 13 | Must |
| 2.4 | 3NF Schema Documentation | 2 | 3 | Must |
| 2.5 | Semantic Search Implementation (pgvector) | 2 | 8 | Must |
| 2.6 | Python Service | 2 | 5 | Must |
| 2.7 | Views | 2 | 3 | Should |
| 2.8 | Simple Search Frontend | 2 | 3 | Should |
| 2.9 | Performance Benchmarking (Vector vs LIKE) | 2 | 5 | Should |
| 2.10 | Sprint 2 Review | 2 | 1 | Must |

---

## Story Outcomes



## 2.1 Docker Compose Setup



## 2.2 PostgresSQL Schema Implementation



## Story 2.3 — Database Abstractions: Triggers, Stored Procedures, Functions
 
**Points:** 13 | **Status:** Complete
 
### Goal
 
Implement business logic at the database level using triggers and stored procedures, so that critical operations are atomic, consistent, and cannot be bypassed by application code.
This section will also include test scenarios and their outcome based around these triggers and  stored procedures.
 
The expert's requirement: for each abstraction, document the scenario, the mechanism chosen, and the justification.
 
---
 
### Umbrella term: Datenbankabstraktionen
 
The following abstractions were implemented. Each is categorised as either a **Trigger** or a **Stored Procedure**.

**Triggers** fire automatically in response to a database event (INSERT, UPDATE, DELETE). They cannot be called explicitly and cannot be bypassed by application code. Used when the logic must always execute as a side effect of a data change.

**Stored Procedures** are called explicitly by the application. They contain multi-step business logic and have full transaction control. Used when an operation spans multiple tables and must be atomic.

---
 
### Triggers
 
#### Trigger 1 — Price History Logging
 
**Scenario:** When a shop employee updates the price of an inventory entry, the change must be recorded automatically. Without this, there is no audit trail and price history is lost.
 
**Mechanism:** `AFTER UPDATE` trigger on `inventory`, scoped to the `price` column. A `WHEN` guard (`OLD.price IS DISTINCT FROM NEW.price`) ensures the trigger only fires on actual price changes, not on unrelated row updates.
 
**Why a trigger:** Must fire on every price change regardless of what caused it — a trigger cannot be bypassed by application code.
 
```sql
CREATE OR REPLACE FUNCTION fn_log_price_change()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO price_history (inventory_id, old_price, new_price)
    VALUES (OLD.id, OLD.price, NEW.price);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
 
CREATE TRIGGER trg_log_price_change
AFTER UPDATE OF price ON inventory
FOR EACH ROW
WHEN (OLD.price IS DISTINCT FROM NEW.price)
EXECUTE FUNCTION fn_log_price_change();
```
 
---
 
#### Trigger 2 — Order Status Sync on Payment Confirmation
 
**Scenario:** When a payment is marked as `completed`, the associated order should automatically transition from `pending` to `confirmed`. Requiring two separate updates from the application creates a window where order and payment state can be inconsistent.
 
**Mechanism:** `AFTER UPDATE` trigger on `payments`, scoped to the `status` column. The function checks for the specific `pending → completed` transition before acting, so re-confirming an already-completed payment has no effect.
 
**Why a trigger:** Order status must reflect payment status automatically — a trigger guarantees this regardless of which code path updates the payment.
 
```sql
CREATE OR REPLACE FUNCTION fn_sync_order_on_payment()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' AND OLD.status IS DISTINCT FROM 'completed' THEN
        UPDATE orders
        SET status     = 'confirmed',
            updated_at = NOW()
        WHERE id = NEW.order_id
          AND status = 'pending';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
 
CREATE TRIGGER trg_sync_order_on_payment
AFTER UPDATE OF status ON payments
FOR EACH ROW
EXECUTE FUNCTION fn_sync_order_on_payment();
```
 
---
 
#### Trigger 3 — Auto-update `updated_at`
 
**Scenario:** `updated_at` must always reflect the true last-modification time of a row. Relying on application code to set this is unreliable — any direct SQL update would bypass it.
 
**Mechanism:** `BEFORE UPDATE` trigger on `inventory`, `orders`, and `customers`. A single shared function `fn_set_updated_at` is registered on all three tables. Uses `clock_timestamp()` rather than `NOW()` — `NOW()` returns transaction start time and does not advance within a transaction, which caused test failures during development.
 
**Why a trigger:** Must fire on every update to all three tables — a trigger guarantees this without relying on application code.
 
```sql
CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = clock_timestamp();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
 
CREATE TRIGGER trg_updated_at_inventory
BEFORE UPDATE ON inventory FOR EACH ROW
EXECUTE FUNCTION fn_set_updated_at();
 
CREATE TRIGGER trg_updated_at_orders
BEFORE UPDATE ON orders FOR EACH ROW
EXECUTE FUNCTION fn_set_updated_at();
 
CREATE TRIGGER trg_updated_at_customers
BEFORE UPDATE ON customers FOR EACH ROW
EXECUTE FUNCTION fn_set_updated_at();
```
 
---
 
### Stored Procedures
 
#### SP 1 — `process_purchase`
 
**Scenario:** A customer buys a card. This spans six tables: `inventory`, `orders`, `order_items`, `payments`, `deliveries`, and requires the `customers` record. All steps must succeed together or none at all — a partial write leaves the database in an inconsistent state.
 
**Mechanism:** Stored procedure with full transaction control. Stock is checked and locked with `SELECT FOR UPDATE` before deduction. This prevents a race condition where two concurrent purchases could both read the same available quantity and both succeed when only enough stock exists for one.
 
**Why a stored procedure:** Multi-step operation spanning six tables, called explicitly by the application. Returns the created `order_id` to the caller via an OUT parameter.
 
**Key design decision:** `unit_price` in `order_items` is a snapshot of the price at time of purchase. If `inventory.price` changes later, historical orders retain the original price.
 
```sql
CREATE OR REPLACE PROCEDURE process_purchase(
    p_customer_id    INT,
    p_inventory_id   INT,
    p_quantity       INT,
    p_payment_method payment_method,
    OUT p_order_id   INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_available   INT;
    v_price       NUMERIC(10, 2);
    v_card_id     INT;
    v_ship_addr   TEXT;
BEGIN
    SELECT quantity, price, card_id
    INTO v_available, v_price, v_card_id
    FROM inventory
    WHERE id = p_inventory_id
    FOR UPDATE;
 
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Inventory entry % does not exist', p_inventory_id;
    END IF;
 
    IF v_available < p_quantity THEN
        RAISE EXCEPTION 'Insufficient stock: requested %, available %', p_quantity, v_available;
    END IF;
 
    SELECT shipping_address INTO v_ship_addr
    FROM customers WHERE id = p_customer_id;
 
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer % does not exist', p_customer_id;
    END IF;
 
    UPDATE inventory SET quantity = quantity - p_quantity WHERE id = p_inventory_id;
 
    INSERT INTO orders (customer_id, status)
    VALUES (p_customer_id, 'pending')
    RETURNING id INTO p_order_id;
 
    INSERT INTO order_items (order_id, card_id, quantity, unit_price)
    VALUES (p_order_id, v_card_id, p_quantity, v_price);
 
    INSERT INTO payments (order_id, amount, method, status)
    VALUES (p_order_id, v_price * p_quantity, p_payment_method, 'pending');
 
    INSERT INTO deliveries (order_id, address, status, estimated_date)
    VALUES (p_order_id, COALESCE(v_ship_addr, ''), 'pending', CURRENT_DATE + INTERVAL '5 days');
 
EXCEPTION
    WHEN OTHERS THEN RAISE;
END;
$$;
```
 
---
 
#### SP 2 — `cancel_order`
 
**Scenario:** A customer or employee cancels an order that is still `pending` or `confirmed`. Inventory must be restored and payment and delivery statuses updated consistently.
 
**Mechanism:** Stored procedure. Guards against invalid cancellations (shipped or delivered orders cannot be cancelled through this path — that requires a returns flow). Restores inventory per order item.
 
**Why a stored procedure:** Cancellation is an explicit action with conditional logic — it must be called intentionally, not fire automatically on every status change.

**Known limitation:** The inventory restore targets the first matching `card_id` row rather than the exact original `card_id + condition` combination. If the original inventory entry was deleted after the purchase, stock is still restored but to a different condition entry. This is acceptable for a shop prototype but would require tracking `inventory_id` in `order_items` in a production system.
 
```sql
CREATE OR REPLACE PROCEDURE cancel_order(p_order_id INT)
LANGUAGE plpgsql AS $$
DECLARE
    v_status order_status;
    v_item   RECORD;
    v_inv_id INT;
BEGIN
    SELECT status INTO v_status FROM orders
    WHERE id = p_order_id FOR UPDATE;
 
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Order % does not exist', p_order_id;
    END IF;
 
    IF v_status NOT IN ('pending', 'confirmed') THEN
        RAISE EXCEPTION 'Cannot cancel order % with status %', p_order_id, v_status;
    END IF;
 
    FOR v_item IN
        SELECT card_id, quantity FROM order_items WHERE order_id = p_order_id
    LOOP
        SELECT id INTO v_inv_id FROM inventory WHERE card_id = v_item.card_id LIMIT 1;
        IF FOUND THEN
            UPDATE inventory SET quantity = quantity + v_item.quantity WHERE id = v_inv_id;
        END IF;
    END LOOP;
 
    UPDATE orders  SET status = 'cancelled' WHERE id = p_order_id;
    UPDATE payments SET status = 'refunded'  WHERE order_id = p_order_id AND status IN ('pending', 'completed');
    UPDATE deliveries SET status = 'returned' WHERE order_id = p_order_id AND status = 'pending';
 
EXCEPTION
    WHEN OTHERS THEN RAISE;
END;
$$;
```
 
---
 
#### SP 3 — `restock_inventory`
 
**Scenario:** New stock arrives for a card. If an entry already exists for that `card_id + condition` pair, quantity is incremented. If not, a new entry is created. Without this logic, a restock could create duplicate rows for the same card and condition.
 
**Mechanism:** Stored procedure. Checks for an existing entry first. The `p_update_price` parameter controls whether the price is overwritten — a routine restock does not change the price unless explicitly requested.
 
**Why a stored procedure:** Restock requires conditional logic (insert vs. update) that belongs in the database, not the application layer.

**Interaction with Trigger 1:** When `p_update_price = TRUE`, the price update on the existing row fires `trg_log_price_change` automatically. No additional code needed.
 
```sql
CREATE OR REPLACE PROCEDURE restock_inventory(
    p_card_id      INT,
    p_condition    card_condition,
    p_quantity     INT,
    p_price        NUMERIC(10, 2),
    p_update_price BOOLEAN DEFAULT FALSE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_existing_id INT;
BEGIN
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Restock quantity must be greater than 0';
    END IF;
 
    SELECT id INTO v_existing_id
    FROM inventory WHERE card_id = p_card_id AND condition = p_condition;
 
    IF FOUND THEN
        IF p_update_price THEN
            UPDATE inventory SET quantity = quantity + p_quantity, price = p_price
            WHERE id = v_existing_id;
        ELSE
            UPDATE inventory SET quantity = quantity + p_quantity WHERE id = v_existing_id;
        END IF;
    ELSE
        INSERT INTO inventory (card_id, condition, quantity, price)
        VALUES (p_card_id, p_condition, p_quantity, p_price);
    END IF;
END;
$$;
```
 
---
 
#### SP 4 — `bulk_price_update`
 
**Scenario:** Market prices change and the shop needs to update multiple inventory entries at once. Running individual UPDATE statements would be error-prone and verbose.
 
**Mechanism:** Stored procedure accepting an array of `price_update_input` composite type `(inventory_id, new_price)`. Iterates and updates each entry. The `IS DISTINCT FROM` guard in `trg_log_price_change` means only actual price changes are logged — passing the same price as before produces no `price_history` row.
 
**Why a stored procedure:** Batch update called explicitly by the application — validation and audit logging are enforced in one place.

```sql
CREATE TYPE price_update_input AS (
    inventory_id INT,
    new_price    NUMERIC(10, 2)
);
 
CREATE OR REPLACE PROCEDURE bulk_price_update(p_updates price_update_input[])
LANGUAGE plpgsql AS $$
DECLARE
    v_entry price_update_input;
BEGIN
    FOREACH v_entry IN ARRAY p_updates LOOP
        IF v_entry.new_price <= 0 THEN
            RAISE EXCEPTION 'Price must be greater than 0 for inventory_id %', v_entry.inventory_id;
        END IF;
        UPDATE inventory SET price = v_entry.new_price WHERE id = v_entry.inventory_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Inventory entry % does not exist', v_entry.inventory_id;
        END IF;
    END LOOP;
END;
$$;
```
 
---
 
### Tests
 
All tests are in `06_tests.sql`. The entire file runs inside a `BEGIN / ROLLBACK` block — no test data is persisted to the database.
 
Test data is isolated using a dedicated card (`id=9999`, name `Testmon`) and a temporary table `test_ctx` that captures its inventory id at runtime. This avoids conflicts with real seed data.
 
---
 
#### TEST 1 — `trg_updated_at` fires on inventory UPDATE
 
**Abstraction under test:** `trg_updated_at_inventory` / `fn_set_updated_at`
 
**Setup:** Read `updated_at` before update. Sleep 0.1s to ensure clock_timestamp() advances between the two reads.
 
**Action:** `UPDATE inventory SET quantity = quantity + 0` — a no-op update that still fires the trigger.
 
**Assertion:** `updated_at` after > `updated_at` before.
 
**Note:** `clock_timestamp()` is used in the trigger instead of `NOW()`. `NOW()` returns transaction start time and does not advance within a transaction, which caused this test to fail during development.
 
**Result:** `PASSED` — `updated_at` advanced from `09:48:09.829` to `09:48:09.933`
 
---
 
#### TEST 2 — `trg_log_price_change` logs a price change
 
**Abstraction under test:** `trg_log_price_change` / `fn_log_price_change`
 
**Setup:** Read current price of test inventory entry.
 
**Action:** `UPDATE inventory SET price = 59.99`
 
**Assertion:** Exactly 1 row in `price_history` with matching `inventory_id`, `old_price`, and `new_price = 59.99`.
 
**Result:** `PASSED` — price change logged correctly (9.12 → 59.99)
 
---
 
#### TEST 3 — `trg_log_price_change` does NOT fire on non-price update
 
**Abstraction under test:** `trg_log_price_change` WHEN guard (`OLD.price IS DISTINCT FROM NEW.price`)
 
**Setup:** Count existing `price_history` rows for test entry.
 
**Action:** `UPDATE inventory SET quantity = 10` — price column not touched.
 
**Assertion:** `price_history` count is unchanged.
 
**Result:** `PASSED` — no spurious audit row created
 
---
 
#### TEST 4 — `trg_sync_order_on_payment` confirms order on payment completion
 
**Abstraction under test:** `trg_sync_order_on_payment` / `fn_sync_order_on_payment`
 
**Setup:** Insert a `pending` order and a `pending` payment for test customer.
 
**Action:** `UPDATE payments SET status = 'completed'`
 
**Assertion:** `orders.status` = `confirmed`.
 
**Result:** `PASSED` — order confirmed automatically after payment update
 
---
 
#### TEST 5 — `process_purchase` happy path
 
**Abstraction under test:** `process_purchase` stored procedure
 
**Setup:** Reset test inventory to `quantity = 10`.
 
**Action:** `CALL process_purchase(customer_id=1, inventory_id=<test>, quantity=2, method='credit_card')`
 
**Assertions:**
- `inventory.quantity` = 8 (reduced by 2)
- 1 row in `order_items` for the new order
- 1 row in `payments` for the new order
- 1 row in `deliveries` for the new order
**Result:** `PASSED` — inventory reduced, all related records created
 
---
 
#### TEST 6 — `process_purchase` rejects purchase when stock is insufficient
 
**Abstraction under test:** Stock check and `SELECT FOR UPDATE` in `process_purchase`
 
**Setup:** Set test inventory `quantity = 1`.
 
**Action:** `CALL process_purchase(quantity=5)` — requests more than available.
 
**Assertion:** Exception is raised. `inventory.quantity` remains unchanged at 1.
 
**Result:** `PASSED` — exception raised, inventory unchanged at 1
 
---
 
#### TEST 7 — `cancel_order` reverses a purchase
 
**Abstraction under test:** `cancel_order` stored procedure
 
**Setup:** Reset test inventory to `quantity = 10`. Call `process_purchase` with `quantity=2` to create a real order.
 
**Action:** `CALL cancel_order(<order_id>)`
 
**Assertions:**
- `inventory.quantity` restored to 10
- `orders.status` = `cancelled`
- `payments.status` = `refunded`
**Result:** `PASSED` — order cancelled, stock restored, payment refunded
 
---
 
#### TEST 8 — `restock_inventory` increments existing entry without creating duplicates
 
**Abstraction under test:** `restock_inventory` stored procedure
 
**Setup:** Read current quantity of test card (`card_id=9999`, `condition=mint`).
 
**Action:** `CALL restock_inventory(card_id=9999, condition='mint', quantity=5, update_price=FALSE)`
 
**Assertions:**
- `quantity` = previous quantity + 5
- Exactly 1 row exists for `card_id=9999 AND condition='mint'` (no duplicate created)
**Result:** `PASSED` — quantity 10 → 15, no duplicate row
 
---
 
#### TEST 9 — `bulk_price_update` updates price and triggers audit log
 
**Abstraction under test:** `bulk_price_update` stored procedure + `trg_log_price_change` interaction
 
**Setup:** Reset test inventory price to 49.99. Clear existing `price_history` rows for test entry.
 
**Action:** `CALL bulk_price_update(ARRAY[(inv_id, 75.00)])`
 
**Assertions:**
- `inventory.price` = 75.00
- Exactly 1 row in `price_history` (trigger fired automatically via `bulk_price_update`)
**Result:** `PASSED` — price updated to 75.00, price_history row created
 
---
 
#### Coverage summary
 
| # | Abstraction | Type | Result |
|---|---|---|---|
| 1 | `trg_updated_at` | Trigger | PASSED |
| 2 | `trg_log_price_change` — fires on change | Trigger | PASSED |
| 3 | `trg_log_price_change` — does not fire without change | Trigger (WHEN guard) | PASSED |
| 4 | `trg_sync_order_on_payment` | Trigger | PASSED |
| 5 | `process_purchase` — success path | Stored Procedure | PASSED |
| 6 | `process_purchase` — out of stock rejection | Stored Procedure | PASSED |
| 7 | `cancel_order` | Stored Procedure | PASSED |
| 8 | `restock_inventory` | Stored Procedure | PASSED |
| 9 | `bulk_price_update` + trigger interaction | Stored Procedure | PASSED |
 
**Known untested edge cases:** cancelling a shipped order, purchasing from a non-existent customer, `bulk_price_update` with price = 0, `restock_inventory` creating a new entry. These would be covered in a production test suite but are out of scope for this prototype.
 
---
 
### Reflection
 
PL/pgSQL was new going into this story. One issue came up during testing that required a change to the trigger implementation.
 
---
 
#### Problem — `NOW()` does not advance within a transaction
 
**Failure output:**
```
WARNING:  TEST 1 FAILED: updated_at did not change
```
 
**Cause:** `fn_set_updated_at` used `NOW()`, which returns the timestamp at transaction start and stays frozen for the entire transaction. The before and after reads returned the same value even after the update.
 
**Fix:** Changed `fn_set_updated_at` to use `clock_timestamp()`, which returns real wall time and advances even within a transaction.
 
```sql
-- Before (broken)
NEW.updated_at = NOW();
 
-- After (fixed)
NEW.updated_at = clock_timestamp();
```
 
---
 
#### Design limitation — `cancel_order` inventory restore
 
`cancel_order` restores stock to the first matching inventory entry for that card, not necessarily the exact one originally purchased. This happens because `order_items` does not store `inventory_id`. A known limitation — fixing it mid-sprint would have required a schema change.
 
---
 
#### `SELECT FOR UPDATE` in `process_purchase`
 
When two purchases happen at the exact same time, both read the database simultaneously. Without the lock, both see `quantity = 1`, both think there's enough stock, and both go through — ending at `quantity = -1`.
 
`SELECT FOR UPDATE` makes the second purchase wait until the first one is done. By then the quantity is already 0, so it gets rejected cleanly.

---

## 2.4 3NF Schema Documentation

**Points:** 3 | **Status:** Complete

### Goal

Demonstrate that the Smart DB schema satisfies Third Normal Form (3NF) by documenting functional dependencies per table and justifying any design decisions that affect normalisation.

---

### Normalisation recap

**3NF rule:** Every non-key column must depend only on the primary key — not on another non-key column.

**2NF** is automatically satisfied because all tables use a single `id` as primary key. There are no composite keys, so no partial dependencies can exist.

---

### Table-by-table analysis

#### `sets`

| Column | Depends on |
|---|---|
| name | id |
| release_date | id |

**3NF satisfied.**

---

#### `cards`

| Column | Depends on |
|---|---|
| name | id |
| number | id |
| rarity | id |
| set_id | id |
| vector | id |

`set_id` is a foreign key reference, not a transitive dependency. `vector` is an embedding generated from name and rarity at insert time; once stored it depends on `id` and does not create a dependency between other columns. **3NF satisfied.**

---

#### `customers`

| Column | Depends on |
|---|---|
| name | id |
| email | id |
| address | id |
| shipping_address | id |
| created_at | id |
| updated_at | id |

`address` and `shipping_address` are independent columns, both describing the customer directly. Neither depends on the other. **3NF satisfied.**

---

#### `inventory`

| Column | Depends on |
|---|---|
| card_id | id |
| condition | id |
| quantity | id |
| price | id |
| created_at | id |
| updated_at | id |

`price` is set per inventory entry and does not depend on `condition`. `quantity` does not depend on `price`. **3NF satisfied.**

---

#### `price_history`

| Column | Depends on |
|---|---|
| inventory_id | id |
| old_price | id |
| new_price | id |
| changed_at | id |

Point-in-time snapshot. `old_price` and `new_price` are recorded at the moment of change; neither is derived from the other. **3NF satisfied.**

---

#### `orders`

| Column | Depends on |
|---|---|
| customer_id | id |
| status | id |
| created_at | id |
| updated_at | id |

No derived or calculated columns. A `total` column was considered during design but removed because it could be derived by summing `order_items.quantity * unit_price`, which would violate 3NF. Order total is computed from `order_items` via the `order_summary` view. **3NF satisfied.**

---

#### `order_items`

| Column | Depends on |
|---|---|
| order_id | id |
| card_id | id |
| quantity | id |
| unit_price | id |

`unit_price` is a price snapshot at time of purchase, not a reference to `inventory.price`. This is intentional: inventory prices change over time, but the price a customer paid must not change retroactively. It depends directly on the row, not transitively on any other column. **3NF satisfied.**

---

#### `deliveries`

| Column | Depends on |
|---|---|
| order_id | id |
| address | id |
| status | id |
| estimated_date | id |

`address` is a snapshot of `customers.shipping_address` copied at order time. It is stored on the delivery row so that later changes to the customer profile do not affect historical records. **3NF satisfied.**

---

#### `payments`

| Column | Depends on |
|---|---|
| order_id | id |
| amount | id |
| method | id |
| status | id |

`amount` does not depend on `method`. `status` does not depend on `amount`. **3NF satisfied.**

---

### Summary

| Table | 3NF | Notes |
|---|---|---|
| sets | ✓ | — |
| cards | ✓ | vector stored at insert, not a transitive dependency |
| customers | ✓ | — |
| inventory | ✓ | — |
| price_history | ✓ | snapshot table by design |
| orders | ✓ | total removed; computed via order_summary view |
| order_items | ✓ | unit_price is a snapshot, not a derived value |
| deliveries | ✓ | address is a snapshot, not a reference |
| payments | ✓ | — |

All tables satisfy 3NF.

---

## 2.5 Semantic Search Implementation (pgvector)

**Points:** 8 | **Status:** Complete

### Goal

Implement semantic search over the card catalogue using pgvector, so that users can find cards by approximate or misspelled names — something LIKE search cannot handle. Compare both approaches with real query results.

---

### How it works

Each card is represented as a text string combining its name, rarity, and set name:

```
"Mega Charizard X ex Ultra Rare Phantasmal Flames"
```

This string is converted to a 384-dimension vector using the `all-MiniLM-L6-v2` model from `sentence-transformers`. The vector is stored in `cards.vector`. At search time, the query is embedded using the same model and pgvector finds the nearest neighbours by L2 distance.

**Why this text combination:** name and rarity are the attributes a user would search by. Set name adds context that helps distinguish cards with the same name across sets. No manual description is needed — the data already has everything required.

**Model choice — `all-MiniLM-L6-v2`:** Produces 384-dimension vectors, matching the `VECTOR(384)` column in the schema. Lightweight, loads in seconds, and runs fully locally inside Docker with no external API calls. A larger model like `all-mpnet-base-v2` produces 768-dimension vectors and would be more accurate, but requires a schema change, uses more memory, and is slower at query time. For 242 short card name strings the accuracy difference is not meaningful.

---

### Implementation

**Embedding generation — `import_cards.py`**

Reads `sets.csv` and `cards.csv`, generates one embedding per card, and inserts all records with their vectors in a single pass. Run once after `docker compose up`:

```bash
docker exec smart_db_service python import_cards.py
```

**Vector search — `/search`**

```python
embedding = MODEL.encode(query).tolist()
cur.execute("""
    SELECT c.id, c.name, c.rarity, s.name AS set_name,
           c.vector <-> %s::vector AS distance
    FROM cards c
    JOIN sets s ON c.set_id = s.id
    ORDER BY distance
    LIMIT 10
""", (embedding,))
```

The `<->` operator is pgvector's L2 distance. Lower distance = more similar.

**LIKE search — `/search/like`**

```sql
WHERE c.name ILIKE %s OR c.rarity ILIKE %s OR s.name ILIKE %s
```

Case-insensitive substring match across name, rarity, and set name. Fast, but requires the exact characters to be present.

---

### Comparison: vector search vs LIKE

Test query: `charizard` (clean) and `charirzard` (typo — extra `r`).

#### Clean query — `charizard`

**Vector search (`/search?q=charizard`)**

| # | Name | Rarity | Set | Distance |
|---|---|---|---|---|
| 1 | Mega Charizard Y ex | Mega Hyper Rare | Ascended Heroes | 0.9802 |
| 2 | Mega Charizard X ex | Mega Hyper Rare | Phantasmal Flames | 0.9965 |
| 3 | Mega Charizard X ex | Ultra Rare | Phantasmal Flames | 1.0112 |
| 4 | Mega Charizard X ex | Special Illustration Rare | Phantasmal Flames | 1.0383 |
| 5 | Mega Dragonite ex | Mega Hyper Rare | Ascended Heroes | 1.1437 |

**LIKE search (`/search/like?q=charizard`)**

| # | Name | Rarity | Set |
|---|---|---|---|
| 1 | Mega Charizard X ex | Ultra Rare | Phantasmal Flames |
| 2 | Mega Charizard X ex | Special Illustration Rare | Phantasmal Flames |
| 3 | Mega Charizard X ex | Mega Hyper Rare | Phantasmal Flames |
| 4 | Mega Charizard Y ex | Mega Hyper Rare | Ascended Heroes |

Both return the 4 Charizard cards. LIKE returns exactly those 4. Vector returns the same 4 plus 6 loosely related cards ranked by distance.

---

#### Typo query — `charirzard`

**Vector search (`/search?q=charirzard`)**

| # | Name | Rarity | Set | Distance |
|---|---|---|---|---|
| 1 | Mega Charizard Y ex | Mega Hyper Rare | Ascended Heroes | 1.1110 |
| 2 | Mega Charizard X ex | Mega Hyper Rare | Phantasmal Flames | 1.1445 |
| 3 | Mega Charizard X ex | Ultra Rare | Phantasmal Flames | 1.1451 |
| 4 | Psyduck | Illustration Rare | Ascended Heroes | 1.1577 |
| 5 | Mega Charizard X ex | Special Illustration Rare | Phantasmal Flames | 1.1581 |

**LIKE search (`/search/like?q=charirzard`)** — no results.

Vector search still surfaces all 3 Charizard X ex variants and Mega Charizard Y ex within the top 5 results despite the typo. LIKE returns nothing.

---

### Results summary

| | Clean query | Typo query |
|---|---|---|
| Vector search | ✓ Correct results, distances 0.98–1.04 | ✓ Charizards in top 5, distances 1.11–1.16 |
| LIKE search | ✓ Exact matches only | ✗ No results |

**Conclusion:** For clean queries both approaches return the same relevant cards. The difference is typo tolerance — LIKE fails completely on `charirzard`, vector search recovers the correct cards. The trade-off is precision: vector search always returns 10 results ranked by distance, including noise, while LIKE returns only exact matches with no ranking. For a card shop where users may mistype names, vector search provides meaningful resilience that LIKE cannot.

The distances on the typo query (1.11–1.18) are noticeably higher than the clean query (0.98–1.04), showing the model's reduced confidence — the results are correct but the signal is weaker.

---

## Sprint Review

*To be completed at end of Sprint 2.*

**Points committed:** 46 / **Points completed:** —

---

## Retrospective

| What went well | What did not go well | What to change |
|---|---|---|
| | | |