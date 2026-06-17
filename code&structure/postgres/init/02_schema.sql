-- =============================================================
-- Smart DB — Pokémon Card Shop Schema
-- =============================================================

-- ENUMS
CREATE TYPE order_status AS ENUM ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled');
CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded');
CREATE TYPE payment_method AS ENUM ('credit_card', 'debit_card', 'paypal', 'bank_transfer');
CREATE TYPE delivery_status AS ENUM ('pending', 'dispatched', 'in_transit', 'delivered', 'returned');
CREATE TYPE card_condition AS ENUM ('mint', 'near_mint', 'excellent', 'good', 'played', 'poor');

-- =============================================================
-- SETS
-- =============================================================
CREATE TABLE sets (
    id            SERIAL PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    release_date  DATE NOT NULL
);

-- =============================================================
-- CARDS
-- =============================================================
CREATE TABLE cards (
    id       SERIAL PRIMARY KEY,
    name     VARCHAR(100) NOT NULL,
    number   VARCHAR(20)  NOT NULL,
    rarity   VARCHAR(50)  NOT NULL,
    set_id   INT          NOT NULL REFERENCES sets(id),
    vector   VECTOR(384)
);

CREATE INDEX idx_cards_set_id ON cards(set_id);
CREATE INDEX idx_cards_rarity  ON cards(rarity);

-- =============================================================
-- CUSTOMERS
-- =============================================================
CREATE TABLE customers (
    id               SERIAL PRIMARY KEY,
    name             VARCHAR(100) NOT NULL,
    email            VARCHAR(150) NOT NULL UNIQUE,
    address          TEXT,
    shipping_address TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================
-- INVENTORY
-- =============================================================
CREATE TABLE inventory (
    id          SERIAL PRIMARY KEY,
    card_id     INT             NOT NULL REFERENCES cards(id),
    condition   card_condition  NOT NULL,
    quantity    INT             NOT NULL DEFAULT 0,
    price       NUMERIC(10, 2)  NOT NULL,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_quantity CHECK (quantity >= 0),
    CONSTRAINT chk_price    CHECK (price > 0)
);

CREATE INDEX idx_inventory_card_id ON inventory(card_id);

-- =============================================================
-- PRICE HISTORY
-- =============================================================
CREATE TABLE price_history (
    id            SERIAL PRIMARY KEY,
    inventory_id  INT            NOT NULL REFERENCES inventory(id),
    new_price     NUMERIC(10, 2) NOT NULL,
    changed_at    TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

-- =============================================================
-- ORDERS
-- =============================================================
CREATE TABLE orders (
    id          SERIAL PRIMARY KEY,
    customer_id INT           NOT NULL REFERENCES customers(id),
    status      order_status  NOT NULL DEFAULT 'pending',
    created_at  TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_orders_customer_id ON orders(customer_id);

-- =============================================================
-- ORDER ITEMS
-- =============================================================
CREATE TABLE order_items (
    id          SERIAL PRIMARY KEY,
    order_id    INT            NOT NULL REFERENCES orders(id),
    card_id     INT            NOT NULL REFERENCES cards(id),
    quantity    INT            NOT NULL,
    unit_price  NUMERIC(10, 2) NOT NULL,
    CONSTRAINT chk_oi_quantity CHECK (quantity > 0)
);

CREATE INDEX idx_order_items_order_id ON order_items(order_id);

-- =============================================================
-- DELIVERIES
-- =============================================================
CREATE TABLE deliveries (
    id               SERIAL PRIMARY KEY,
    order_id         INT              NOT NULL REFERENCES orders(id),
    address          TEXT             NOT NULL,
    status           delivery_status  NOT NULL DEFAULT 'pending',
    estimated_date   DATE
);

-- =============================================================
-- PAYMENTS
-- =============================================================
CREATE TABLE payments (
    id          SERIAL PRIMARY KEY,
    order_id    INT             NOT NULL REFERENCES orders(id),
    amount      NUMERIC(10, 2)  NOT NULL,
    method      payment_method  NOT NULL,
    status      payment_status  NOT NULL DEFAULT 'pending',
    CONSTRAINT chk_payment_amount CHECK (amount > 0)
);