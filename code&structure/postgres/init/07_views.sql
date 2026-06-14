-- =============================================================
-- Smart DB — Views
-- =============================================================

-- 1. Total value of current inventory (quantity * price per entry)
CREATE OR REPLACE VIEW inventory_value AS
SELECT
    c.name                          AS card_name,
    c.rarity,
    s.name                          AS set_name,
    i.condition,
    i.quantity,
    i.price,
    i.quantity * i.price            AS total_value
FROM inventory i
JOIN cards c ON c.id = i.card_id
JOIN sets  s ON s.id = c.set_id
ORDER BY total_value DESC;

-- =============================================================

-- 2. Top selling cards by total units sold across all orders
CREATE OR REPLACE VIEW top_selling_cards AS
SELECT
    c.name                          AS card_name,
    c.rarity,
    s.name                          AS set_name,
    SUM(oi.quantity)                AS units_sold,
    SUM(oi.quantity * oi.unit_price) AS revenue
FROM order_items oi
JOIN cards  c ON c.id = oi.card_id
JOIN sets   s ON s.id = c.set_id
GROUP BY c.name, c.rarity, s.name
ORDER BY units_sold DESC;

-- =============================================================

-- 3. Low stock — inventory entries with quantity <= 2
CREATE OR REPLACE VIEW low_stock AS
SELECT
    c.name                          AS card_name,
    c.rarity,
    s.name                          AS set_name,
    i.condition,
    i.quantity,
    i.price
FROM inventory i
JOIN cards c ON c.id = i.card_id
JOIN sets  s ON s.id = c.set_id
WHERE i.quantity <= 2
ORDER BY i.quantity ASC, c.name ASC;

-- =============================================================

-- 4. Out of stock — inventory entries with quantity = 0
CREATE OR REPLACE VIEW out_of_stock AS
SELECT
    c.name                          AS card_name,
    c.rarity,
    s.name                          AS set_name,
    i.condition,
    i.price
FROM inventory i
JOIN cards c ON c.id = i.card_id
JOIN sets  s ON s.id = c.set_id
WHERE i.quantity = 0
ORDER BY c.name ASC;

-- =============================================================

-- 5. Revenue by set — total revenue from sold cards grouped by set
CREATE OR REPLACE VIEW revenue_by_set AS
SELECT
    s.name                           AS set_name,
    COUNT(DISTINCT oi.id)            AS items_sold,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM order_items oi
JOIN cards c ON c.id = oi.card_id
JOIN sets  s ON s.id = c.set_id
GROUP BY s.name
ORDER BY total_revenue DESC;

-- =============================================================

-- 6. Order summary — one row per order with customer, card, and status
CREATE OR REPLACE VIEW order_summary AS
SELECT
    o.id                             AS order_id,
    cu.name                          AS customer_name,
    c.name                           AS card_name,
    c.rarity,
    s.name                           AS set_name,
    oi.quantity,
    oi.unit_price,
    oi.quantity * oi.unit_price      AS order_total,
    o.status                         AS order_status,
    p.method                         AS payment_method,
    p.status                         AS payment_status,
    d.status                         AS delivery_status,
    o.created_at
FROM orders o
JOIN customers  cu ON cu.id = o.customer_id
JOIN order_items oi ON oi.order_id = o.id
JOIN cards       c  ON c.id = oi.card_id
JOIN sets        s  ON s.id = c.set_id
JOIN payments    p  ON p.order_id = o.id
JOIN deliveries  d  ON d.order_id = o.id
ORDER BY o.created_at DESC;