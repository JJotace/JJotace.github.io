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




## 2.2 


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
 
**Why a trigger and not a stored procedure:** The requirement is passive — it must fire on every price change regardless of what caused it. A trigger cannot be bypassed. A stored procedure would have to be called explicitly and could be skipped.
 
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
 
**Why a trigger:** State consistency between two related tables is exactly the use case for a trigger. The order status is a derived consequence of the payment status — enforcing this at the DB level guarantees consistency.
 
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
 
**Why a trigger:** This is a cross-cutting concern. A trigger guarantees the field is always accurate regardless of which code path performs the update.
 
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
 
**Why a stored procedure and not a trigger:** This is an explicit, multi-step operation initiated by the application. A trigger cannot span multiple tables in this way. The SP also returns the created `order_id` as an OUT parameter so the caller can reference the new order.
 
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
    v_total       NUMERIC(10, 2);
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
 
    v_total := v_price * p_quantity;
 
    UPDATE inventory SET quantity = quantity - p_quantity WHERE id = p_inventory_id;
 
    INSERT INTO orders (customer_id, status, total)
    VALUES (p_customer_id, 'pending', v_total)
    RETURNING id INTO p_order_id;
 
    INSERT INTO order_items (order_id, card_id, quantity, unit_price)
    VALUES (p_order_id, v_card_id, p_quantity, v_price);
 
    INSERT INTO payments (order_id, amount, method, status)
    VALUES (p_order_id, v_total, p_payment_method, 'pending');
 
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
 
PL/pgSQL was new going into this story. Three issues came up during testing that required changes to both the implementation and the tests.
 
---
 
#### Problem 1 — TEST 2 failed: `price_history` row not found
 
**Failure output:**
```
WARNING:  TEST 2 FAILED: expected 1 price_history row, found 0
```
 
**Cause:** The test hardcoded `old_price = 49.99` in the assertion. The actual seed price for inventory `id=1` was `9.12`, so the trigger fired and logged the change correctly — the assertion just never matched.
 
**Fix:** Read the actual price into a variable before the update and use that in the assertion instead of a hardcoded value.
 
---
 
#### Problem 2 — TEST 8 failed: `restock_inventory` assertion wrong
 
**Failure output (first run):**
```
WARNING:  TEST 8 FAILED: qty=10, rows=1
```
**Failure output (second run):**
```
WARNING:  TEST 8 FAILED: qty=5, rows=1
```
 
**Cause:** The test setup inserted an inventory row with `id=1` using `ON CONFLICT DO NOTHING`. Since `id=1` was already taken by real seed data, the insert was silently skipped. The test then looked up quantity for `inventory WHERE id = 1`, which pointed to a real card — not the test card. `v_qty_before` was NULL, and `NULL + 5` is NULL in SQL, so the assertion `v_qty_after = v_qty_before + 5` always failed.
 
**Fix:** Removed the hardcoded `id=1` from the inventory seed insert and captured the test card's inventory id at runtime into a `TEMP TABLE test_ctx`. All test blocks then resolve the id from `test_ctx` into a local variable before using it.
 
---
 
#### Problem 3 — `NOW()` does not advance within a transaction
 
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
 
#### Problem 4 — Subqueries not allowed as CALL arguments
 
**Failure output:**
```
ERROR:  cannot use subquery in CALL argument
LINE 3:         p_inventory_id   => (SELECT inv_id FROM test_ctx),
```
 
**Cause:** PL/pgSQL does not allow subqueries directly inside CALL argument lists. This affected both `process_purchase` and `bulk_price_update` calls in the test file.
 
**Fix:** Resolved all subqueries into local variables before the CALL statement.
 
```sql
-- Before (broken)
CALL process_purchase(
    p_inventory_id => (SELECT inv_id FROM test_ctx), ...
);
 
-- After (fixed)
SELECT inv_id INTO v_inv_id FROM test_ctx;
CALL process_purchase(
    p_inventory_id => v_inv_id, ...
);
```
 
---
 
#### Design limitation — `cancel_order` inventory restore
 
`cancel_order` restores stock to the first matching inventory entry for that card, not necessarily the exact one originally purchased. This happens because `order_items` does not store `inventory_id`. A known limitation — fixing it mid-sprint would have required a schema change.
 
---
 
#### `SELECT FOR UPDATE` in `process_purchase`
 
When two purchases happen at the exact same time, both read the database simultaneously. Without the lock, both see `quantity = 1`, both think there's enough stock, and both go through — ending at `quantity = -1`.
 
`SELECT FOR UPDATE` makes the second purchase wait until the first one is done. By then the quantity is already 0, so it gets rejected cleanly.

---

## Sprint Review

*To be completed at end of Sprint 2.*

**Points committed:** 46 / **Points completed:** —

---

## Retrospective

| What went well | What did not go well | What to change |
|---|---|---|
| | | |
