-- =============================================================
-- Smart DB — Triggers
-- =============================================================
-- Trigger 1: Log price changes to price_history
-- Trigger 2: Sync order status to 'confirmed' when payment is completed
-- Trigger 3: Auto-update updated_at on inventory, orders, customers
-- =============================================================


-- -------------------------------------------------------------
-- TRIGGER 1: Price history logging
-- Scenario: When a shop employee updates the price of an inventory
-- entry, the old and new price are automatically recorded in
-- price_history. This is enforced at the database level so no
-- application code can skip the audit trail.
-- Mechanism: AFTER UPDATE trigger on inventory, fires only when
-- the price column actually changes.
-- -------------------------------------------------------------

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


-- -------------------------------------------------------------
-- TRIGGER 2: Order status sync on payment confirmation
-- Scenario: When a payment status is updated to 'completed', the
-- associated order should automatically move from 'pending' to
-- 'confirmed'. This keeps order and payment state consistent
-- without requiring a second explicit update from application code.
-- Mechanism: AFTER UPDATE trigger on payments, fires only when
-- status transitions to 'completed'.
-- -------------------------------------------------------------

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


-- -------------------------------------------------------------
-- TRIGGER 3: Auto-update updated_at
-- Scenario: updated_at should always reflect the last modification
-- time without relying on application code to set it correctly.
-- Mechanism: BEFORE UPDATE trigger on inventory, orders, customers.
-- A single shared function covers all three tables.
-- -------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = clock_timestamp();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_updated_at_inventory
BEFORE UPDATE ON inventory
FOR EACH ROW
EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_updated_at_orders
BEFORE UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_updated_at_customers
BEFORE UPDATE ON customers
FOR EACH ROW
EXECUTE FUNCTION fn_set_updated_at();