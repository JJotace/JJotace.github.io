-- =============================================================
-- Smart DB — Stored Procedures
-- =============================================================
-- SP 1: process_purchase  — full purchase transaction
-- SP 2: cancel_order      — reverse a confirmed/pending order
-- SP 3: restock_inventory — add stock for a card/condition pair
-- SP 4: bulk_price_update — update prices for multiple inventory entries
-- =============================================================


-- -------------------------------------------------------------
-- SP 1: process_purchase
-- Scenario: A customer buys a card. The operation spans multiple
-- tables (inventory, orders, order_items, payments, deliveries)
-- and must be atomic — if any step fails, nothing is committed.
-- Mechanism: Stored procedure with explicit transaction control.
-- Stock is checked and locked with SELECT FOR UPDATE to prevent
-- a race condition where two concurrent purchases could both
-- read the same available quantity.
-- Parameters:
--   p_customer_id    — existing customer
--   p_inventory_id   — specific inventory entry (card + condition)
--   p_quantity       — how many copies to buy
--   p_payment_method — payment method used
-- Returns: order_id of the created order
-- -------------------------------------------------------------

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
    -- Lock the inventory row to prevent concurrent overselling
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

    -- Fetch shipping address
    SELECT shipping_address INTO v_ship_addr
    FROM customers
    WHERE id = p_customer_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer % does not exist', p_customer_id;
    END IF;

    v_total := v_price * p_quantity;

    -- Deduct stock
    UPDATE inventory
    SET quantity = quantity - p_quantity
    WHERE id = p_inventory_id;

    -- Create order
    INSERT INTO orders (customer_id, status, total)
    VALUES (p_customer_id, 'pending', v_total)
    RETURNING id INTO p_order_id;

    -- Create order item (unit_price is a snapshot — price may change later)
    INSERT INTO order_items (order_id, card_id, quantity, unit_price)
    VALUES (p_order_id, v_card_id, p_quantity, v_price);

    -- Create payment (pending — triggers order confirmation when set to completed)
    INSERT INTO payments (order_id, amount, method, status)
    VALUES (p_order_id, v_total, p_payment_method, 'pending');

    -- Create delivery record with address snapshot
    INSERT INTO deliveries (order_id, address, status, estimated_date)
    VALUES (p_order_id, COALESCE(v_ship_addr, ''), 'pending', CURRENT_DATE + INTERVAL '5 days');

EXCEPTION
    WHEN OTHERS THEN
        RAISE;  -- Re-raise; caller's transaction is rolled back
END;
$$;


-- -------------------------------------------------------------
-- SP 2: cancel_order
-- Scenario: A customer or shop employee cancels an order that is
-- still in 'pending' or 'confirmed' state. Inventory must be
-- restored, and order/payment/delivery statuses updated consistently.
-- Orders that are already shipped or delivered cannot be cancelled
-- through this procedure — that would require a return flow.
-- Mechanism: Stored procedure. Checks current status before acting
-- to prevent invalid state transitions.
-- Parameters:
--   p_order_id — order to cancel
-- -------------------------------------------------------------

CREATE OR REPLACE PROCEDURE cancel_order(
    p_order_id INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_status order_status;
    v_item   RECORD;
    v_inv_id INT;
BEGIN
    SELECT status INTO v_status
    FROM orders
    WHERE id = p_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Order % does not exist', p_order_id;
    END IF;

    IF v_status NOT IN ('pending', 'confirmed') THEN
        RAISE EXCEPTION 'Cannot cancel order % with status %', p_order_id, v_status;
    END IF;

    -- Restore inventory for each order item
    FOR v_item IN
        SELECT card_id, quantity FROM order_items WHERE order_id = p_order_id
    LOOP
        -- Find the inventory entry that matches card_id
        -- We restore to the first available entry for that card
        -- (limitation: if the exact condition entry was deleted, this still restores stock)
        SELECT id INTO v_inv_id
        FROM inventory
        WHERE card_id = v_item.card_id
        LIMIT 1;

        IF FOUND THEN
            UPDATE inventory
            SET quantity = quantity + v_item.quantity
            WHERE id = v_inv_id;
        END IF;
    END LOOP;

    -- Update order status
    UPDATE orders
    SET status = 'cancelled'
    WHERE id = p_order_id;

    -- Update payment status
    UPDATE payments
    SET status = 'refunded'
    WHERE order_id = p_order_id
      AND status IN ('pending', 'completed');

    -- Update delivery status
    UPDATE deliveries
    SET status = 'returned'
    WHERE order_id = p_order_id
      AND status = 'pending';

EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
$$;


-- -------------------------------------------------------------
-- SP 3: restock_inventory
-- Scenario: A shop employee receives new stock for a specific
-- card and condition. If an inventory entry already exists for
-- that card/condition pair, quantity is incremented. If not,
-- a new entry is created. This avoids duplicate rows for the
-- same card/condition combination.
-- Mechanism: Stored procedure using INSERT ... ON CONFLICT.
-- Parameters:
--   p_card_id   — card being restocked
--   p_condition — card condition
--   p_quantity  — units received
--   p_price     — price to set (required for new entries;
--                 for existing entries the price is only updated
--                 if p_update_price is TRUE)
--   p_update_price — whether to overwrite the existing price
-- -------------------------------------------------------------

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
    FROM inventory
    WHERE card_id = p_card_id AND condition = p_condition;

    IF FOUND THEN
        IF p_update_price THEN
            UPDATE inventory
            SET quantity = quantity + p_quantity,
                price    = p_price
            WHERE id = v_existing_id;
            -- trg_log_price_change fires automatically if price changed
        ELSE
            UPDATE inventory
            SET quantity = quantity + p_quantity
            WHERE id = v_existing_id;
        END IF;
    ELSE
        INSERT INTO inventory (card_id, condition, quantity, price)
        VALUES (p_card_id, p_condition, p_quantity, p_price);
    END IF;
END;
$$;


-- -------------------------------------------------------------
-- SP 4: bulk_price_update
-- Scenario: The shop updates prices for multiple inventory entries
-- at once (e.g. after market price changes). Each update is applied
-- individually so the price_history trigger fires per row.
-- Mechanism: Stored procedure iterating over an input array of
-- (inventory_id, new_price) pairs.
-- Parameters:
--   p_updates — array of composite type with id and new price
-- -------------------------------------------------------------

-- Composite type for bulk update input
CREATE TYPE price_update_input AS (
    inventory_id INT,
    new_price    NUMERIC(10, 2)
);

CREATE OR REPLACE PROCEDURE bulk_price_update(
    p_updates price_update_input[]
)
LANGUAGE plpgsql AS $$
DECLARE
    v_entry price_update_input;
BEGIN
    FOREACH v_entry IN ARRAY p_updates LOOP
        IF v_entry.new_price <= 0 THEN
            RAISE EXCEPTION 'Price must be greater than 0 for inventory_id %', v_entry.inventory_id;
        END IF;

        UPDATE inventory
        SET price = v_entry.new_price
        WHERE id = v_entry.inventory_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Inventory entry % does not exist', v_entry.inventory_id;
        END IF;
        -- trg_log_price_change fires automatically per row if price changed
    END LOOP;
END;
$$;
