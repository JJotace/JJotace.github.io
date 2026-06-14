-- ===================================================================================================
-- Smart DB — Migration: add image_url to cards
-- This was added into the project later on, and is executed once the database is already in place.
-- ===================================================================================================

ALTER TABLE cards
    ADD COLUMN IF NOT EXISTS image_url TEXT;