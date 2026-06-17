-- =============================================================
-- Smart DB — Abstraction Tests
-- =============================================================
-- Run after: 01_extensions.sql, 02_schema.sql, 03_triggers.sql,
--            04_stored_procedures.sql, and CSV imports.
-- Each test is a self-contained block. Expected outcomes are
-- noted in comments. BEGIN/ROLLBACK removes test changes.
-- =============================================================


-- =============================================================
-- TEST SETUP — seed minimal data
-- =============================================================

BEGIN;

-- Insert a test set and card if not already present from CSV import
INSERT INTO sets (id, name, release_date)
VALUES (99, 'Test Set', '2025-01-01')
ON CONFLICT DO NOTHING;

INSERT INTO cards (id, name, number, rarity, set_id)
VALUES (9999, 'Testmon', 'TST-001', 'IR', 99)
ON CONFLICT DO NOTHING;

INSERT INTO customers (id, name, email, shipping_address)
VALUES (1, 'Test Customer', 'test@example.com', '123 Main St')
ON CONFLICT (email) DO NOTHING;

INSERT INTO inventory (card_id, condition, quantity, price)
VALUES (9999, 'mint', 10, 49.99)
ON CONFLICT DO NOTHING;

-- Capture test inventory id for use across all test blocks
CREATE TEMP TABLE test_ctx AS
SELECT id AS inv_id
FROM inventory
WHERE card_id = 9999 AND condition = 'mint';

-- =============================================================
-- TEST 1: Trigger — updated_at is auto-set on inventory update
-- Expected: updated_at changes after UPDATE
-- =============================================================

DO $$
DECLARE
    v_before TIMESTAMPTZ;
    v_after  TIMESTAMPTZ;
BEGIN
    SELECT updated_at INTO v_before FROM inventory WHERE id = (SELECT inv_id FROM test_ctx);
    PERFORM pg_sleep(0.1);  -- ensure clock advances

    UPDATE inventory SET quantity = quantity + 0 WHERE id = (SELECT inv_id FROM test_ctx);

    SELECT updated_at INTO v_after FROM inventory WHERE id = (SELECT inv_id FROM test_ctx);

    IF v_after > v_before THEN
        RAISE NOTICE 'TEST 1 PASSED: updated_at was updated (% -> %)', v_before, v_after;
    ELSE
        RAISE WARNING 'TEST 1 FAILED: updated_at did not change';
    END IF;
END;
$$;


-- =============================================================
-- TEST 2: Trigger — price change is logged to price_history
-- Expected: one new row in price_history with new_price = 59.99,
--           and the previous price is correctly recoverable via
--           LAG() over new_price (old_price column was removed —
--           see project.md 3NF notes: it was a transitive
--           dependency, derivable from the prior row's new_price)
-- =============================================================

DO $$
DECLARE
    v_old_price   NUMERIC(10,2);
    v_count       INT;
    v_derived_old NUMERIC(10,2);
BEGIN
    SELECT price INTO v_old_price FROM inventory WHERE id = (SELECT inv_id FROM test_ctx);

    UPDATE inventory SET price = 59.99 WHERE id = (SELECT inv_id FROM test_ctx);

    SELECT COUNT(*) INTO v_count
    FROM price_history
    WHERE inventory_id = (SELECT inv_id FROM test_ctx) AND new_price = 59.99;

    -- Confirm the "old" price is still recoverable without storing it:
    -- it's the new_price of the immediately preceding row.
    SELECT old_price INTO v_derived_old
    FROM (
        SELECT new_price,
               LAG(new_price) OVER (PARTITION BY inventory_id ORDER BY changed_at) AS old_price
        FROM price_history
        WHERE inventory_id = (SELECT inv_id FROM test_ctx)
    ) sub
    WHERE new_price = 59.99;

    IF v_count = 1 AND v_derived_old = v_old_price THEN
        RAISE NOTICE 'TEST 2 PASSED: price change logged correctly (% -> 59.99, derived old_price matches)', v_old_price;
    ELSE
        RAISE WARNING 'TEST 2 FAILED: rows found=%, derived old_price=% (expected %)',
            v_count, v_derived_old, v_old_price;
    END IF;

    -- Reset price for subsequent tests
    UPDATE inventory SET price = v_old_price WHERE id = (SELECT inv_id FROM test_ctx);
END;
$$;


-- =============================================================
-- TEST 3: Trigger — no price_history row when price is unchanged
-- Expected: price_history count stays the same
-- =============================================================

DO $$
DECLARE
    v_before INT;
    v_after  INT;
BEGIN
    SELECT COUNT(*) INTO v_before FROM price_history WHERE inventory_id = (SELECT inv_id FROM test_ctx);

    UPDATE inventory SET quantity = 10 WHERE id = (SELECT inv_id FROM test_ctx);  -- price not touched

    SELECT COUNT(*) INTO v_after FROM price_history WHERE inventory_id = (SELECT inv_id FROM test_ctx);

    IF v_after = v_before THEN
        RAISE NOTICE 'TEST 3 PASSED: no price_history row for non-price update';
    ELSE
        RAISE WARNING 'TEST 3 FAILED: unexpected price_history row inserted';
    END IF;
END;
$$;


-- =============================================================
-- TEST 4: Trigger — order confirmed when payment set to completed
-- Expected: order status becomes 'confirmed'
-- =============================================================

DO $$
DECLARE
    v_order_id  INT;
    v_pay_id    INT;
    v_status    order_status;
BEGIN
    INSERT INTO orders (customer_id, status, total)
    VALUES (1, 'pending', 49.99)
    RETURNING id INTO v_order_id;

    INSERT INTO payments (order_id, amount, method, status)
    VALUES (v_order_id, 49.99, 'credit_card', 'pending')
    RETURNING id INTO v_pay_id;

    UPDATE payments SET status = 'completed' WHERE id = v_pay_id;

    SELECT status INTO v_status FROM orders WHERE id = v_order_id;

    IF v_status = 'confirmed' THEN
        RAISE NOTICE 'TEST 4 PASSED: order % confirmed after payment', v_order_id;
    ELSE
        RAISE WARNING 'TEST 4 FAILED: order status is %, expected confirmed', v_status;
    END IF;
END;
$$;


-- =============================================================
-- TEST 5: SP process_purchase — successful purchase
-- Expected: inventory reduced by 2, order created, order_items,
--           payment and delivery rows exist
-- =============================================================

DO $$
DECLARE
    v_order_id   INT;
    v_inv_id     INT;
    v_qty_after  INT;
    v_item_count INT;
    v_pay_count  INT;
    v_del_count  INT;
BEGIN
    SELECT inv_id INTO v_inv_id FROM test_ctx;
    -- Reset inventory to known state
    UPDATE inventory SET quantity = 10 WHERE id = v_inv_id;

    CALL process_purchase(
        p_customer_id    => 1,
        p_inventory_id   => v_inv_id,
        p_quantity       => 2,
        p_payment_method => 'credit_card',
        p_order_id       => v_order_id
    );

    SELECT quantity INTO v_qty_after FROM inventory WHERE id = (SELECT inv_id FROM test_ctx);
    SELECT COUNT(*) INTO v_item_count FROM order_items WHERE order_id = v_order_id;
    SELECT COUNT(*) INTO v_pay_count  FROM payments     WHERE order_id = v_order_id;
    SELECT COUNT(*) INTO v_del_count  FROM deliveries   WHERE order_id = v_order_id;

    IF v_qty_after = 8 AND v_item_count = 1 AND v_pay_count = 1 AND v_del_count = 1 THEN
        RAISE NOTICE 'TEST 5 PASSED: purchase created order %, inventory now %', v_order_id, v_qty_after;
    ELSE
        RAISE WARNING 'TEST 5 FAILED: qty=%, items=%, payments=%, deliveries=%',
            v_qty_after, v_item_count, v_pay_count, v_del_count;
    END IF;
END;
$$;


-- =============================================================
-- TEST 6: SP process_purchase — rejected when out of stock
-- Expected: EXCEPTION raised, inventory unchanged
-- =============================================================

DO $$
DECLARE
    v_qty_before INT;
    v_qty_after  INT;
    v_order_id   INT;
    v_inv_id     INT;
BEGIN
    SELECT inv_id INTO v_inv_id FROM test_ctx;
    UPDATE inventory SET quantity = 1 WHERE id = v_inv_id;
    SELECT quantity INTO v_qty_before FROM inventory WHERE id = v_inv_id;

    BEGIN
        CALL process_purchase(
            p_customer_id    => 1,
            p_inventory_id   => v_inv_id,
            p_quantity       => 5,
            p_payment_method => 'paypal',
            p_order_id       => v_order_id
        );
        RAISE WARNING 'TEST 6 FAILED: expected exception was not raised';
    EXCEPTION
        WHEN OTHERS THEN
            SELECT quantity INTO v_qty_after FROM inventory WHERE id = v_inv_id;
            IF v_qty_after = v_qty_before THEN
                RAISE NOTICE 'TEST 6 PASSED: purchase rejected, inventory unchanged at %', v_qty_after;
            ELSE
                RAISE WARNING 'TEST 6 FAILED: inventory changed despite exception (% -> %)',
                    v_qty_before, v_qty_after;
            END IF;
    END;
END;
$$;


-- =============================================================
-- TEST 7: SP cancel_order — cancels pending order, restores stock
-- Expected: order cancelled, payment refunded, inventory +2
-- =============================================================

DO $$
DECLARE
    v_order_id   INT;
    v_inv_id     INT;
    v_qty_before INT;
    v_qty_after  INT;
    v_ord_status order_status;
    v_pay_status payment_status;
BEGIN
    SELECT inv_id INTO v_inv_id FROM test_ctx;
    UPDATE inventory SET quantity = 10 WHERE id = v_inv_id;
    SELECT quantity INTO v_qty_before FROM inventory WHERE id = v_inv_id;

    CALL process_purchase(
        p_customer_id    => 1,
        p_inventory_id   => v_inv_id,
        p_quantity       => 2,
        p_payment_method => 'debit_card',
        p_order_id       => v_order_id
    );

    CALL cancel_order(v_order_id);

    SELECT quantity    INTO v_qty_after  FROM inventory WHERE id = v_inv_id;
    SELECT status      INTO v_ord_status FROM orders    WHERE id = v_order_id;
    SELECT status      INTO v_pay_status FROM payments  WHERE order_id = v_order_id LIMIT 1;

    IF v_qty_after = v_qty_before
       AND v_ord_status = 'cancelled'
       AND v_pay_status = 'refunded' THEN
        RAISE NOTICE 'TEST 7 PASSED: order % cancelled, stock restored to %', v_order_id, v_qty_after;
    ELSE
        RAISE WARNING 'TEST 7 FAILED: qty=%, order_status=%, pay_status=%',
            v_qty_after, v_ord_status, v_pay_status;
    END IF;
END;
$$;


-- =============================================================
-- TEST 8: SP restock_inventory — increments existing entry
-- Expected: quantity increases, no duplicate row created
-- =============================================================

DO $$
DECLARE
    v_qty_before INT;
    v_qty_after  INT;
    v_row_count  INT;
BEGIN
    SELECT quantity INTO v_qty_before
    FROM inventory WHERE card_id = 9999 AND condition = 'mint';

    CALL restock_inventory(
        p_card_id      => 9999,
        p_condition    => 'mint',
        p_quantity     => 5,
        p_price        => 49.99,
        p_update_price => FALSE
    );

    SELECT quantity INTO v_qty_after
    FROM inventory WHERE card_id = 9999 AND condition = 'mint';

    SELECT COUNT(*) INTO v_row_count
    FROM inventory WHERE card_id = 9999 AND condition = 'mint';

    IF v_qty_after = v_qty_before + 5 AND v_row_count = 1 THEN
        RAISE NOTICE 'TEST 8 PASSED: quantity % -> %, no duplicate row', v_qty_before, v_qty_after;
    ELSE
        RAISE WARNING 'TEST 8 FAILED: qty=%, rows=%', v_qty_after, v_row_count;
    END IF;
END;
$$;


-- =============================================================
-- TEST 9: SP bulk_price_update — updates prices for MULTIPLE
--          inventory entries in a single call
-- Expected: both rows updated to their respective new prices,
--           one price_history row created per changed row
-- =============================================================
 
DO $$
DECLARE
    v_inv_id1     INT;
    v_inv_id2     INT;
    v_price1      NUMERIC(10, 2);
    v_price2      NUMERIC(10, 2);
    v_hist_count1 INT;
    v_hist_count2 INT;
BEGIN
    SELECT inv_id INTO v_inv_id1 FROM test_ctx;
    SELECT inv_id INTO v_inv_id2 FROM test_ctx2;
 
    -- Reset both to known prices (different from targets so the update is real)
    UPDATE inventory SET price = 49.99 WHERE id = v_inv_id1;
    UPDATE inventory SET price = 39.99 WHERE id = v_inv_id2;
    DELETE FROM price_history WHERE inventory_id IN (v_inv_id1, v_inv_id2);
 
    -- Single call, two distinct inventory entries — this is the actual
    -- "bulk" case the procedure is named for.
    CALL bulk_price_update(
        ARRAY[
            ROW(v_inv_id1, 75.00)::price_update_input,
            ROW(v_inv_id2, 55.00)::price_update_input
        ]
    );
 
    SELECT price INTO v_price1 FROM inventory WHERE id = v_inv_id1;
    SELECT price INTO v_price2 FROM inventory WHERE id = v_inv_id2;
    SELECT COUNT(*) INTO v_hist_count1 FROM price_history WHERE inventory_id = v_inv_id1 AND new_price = 75.00;
    SELECT COUNT(*) INTO v_hist_count2 FROM price_history WHERE inventory_id = v_inv_id2 AND new_price = 55.00;
 
    IF v_price1 = 75.00 AND v_price2 = 55.00
       AND v_hist_count1 = 1 AND v_hist_count2 = 1 THEN
        RAISE NOTICE 'TEST 9 PASSED: bulk update applied to 2 entries (% , %), each logged once', v_price1, v_price2;
    ELSE
        RAISE WARNING 'TEST 9 FAILED: price1=%, price2=%, hist1=%, hist2=%',
            v_price1, v_price2, v_hist_count1, v_hist_count2;
    END IF;
END;
$$;
 
 
-- =============================================================
-- TEST 10: SP bulk_price_update — rollback when one entry in the
--          array is invalid
-- Expected: the entire call fails (exception raised), and NEITHER
--           row is updated — proves the loop is atomic across all
--           entries in the array, not just per-row
-- =============================================================
 
DO $$
DECLARE
    v_inv_id1      INT;
    v_inv_id2      INT;
    v_price1_before NUMERIC(10, 2);
    v_price2_before NUMERIC(10, 2);
    v_price1_after  NUMERIC(10, 2);
    v_price2_after  NUMERIC(10, 2);
BEGIN
    SELECT inv_id INTO v_inv_id1 FROM test_ctx;
    SELECT inv_id INTO v_inv_id2 FROM test_ctx2;
 
    UPDATE inventory SET price = 20.00 WHERE id = v_inv_id1;
    UPDATE inventory SET price = 30.00 WHERE id = v_inv_id2;
 
    SELECT price INTO v_price1_before FROM inventory WHERE id = v_inv_id1;
    SELECT price INTO v_price2_before FROM inventory WHERE id = v_inv_id2;
 
    BEGIN
        -- First entry is valid; second entry has a non-positive price,
        -- which bulk_price_update explicitly rejects.
        CALL bulk_price_update(
            ARRAY[
                ROW(v_inv_id1, 99.00)::price_update_input,
                ROW(v_inv_id2, -5.00)::price_update_input
            ]
        );
        RAISE WARNING 'TEST 10 FAILED: expected exception was not raised';
    EXCEPTION
        WHEN OTHERS THEN
            SELECT price INTO v_price1_after FROM inventory WHERE id = v_inv_id1;
            SELECT price INTO v_price2_after FROM inventory WHERE id = v_inv_id2;
 
            IF v_price1_after = v_price1_before AND v_price2_after = v_price2_before THEN
                RAISE NOTICE 'TEST 10 PASSED: invalid entry rejected, both rows unchanged (% , %)',
                    v_price1_after, v_price2_after;
            ELSE
                RAISE WARNING 'TEST 10 FAILED: rows changed despite exception (price1 % -> %, price2 % -> %)',
                    v_price1_before, v_price1_after, v_price2_before, v_price2_after;
            END IF;
    END;
END;
$$;


ROLLBACK;  -- Clean up, can be removed in case test data needs to be kept for some reason.