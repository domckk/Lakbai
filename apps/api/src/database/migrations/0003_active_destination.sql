-- Migration 0003: track each user's active destination on their profile
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS active_destination_id uuid
    REFERENCES destinations(id) ON DELETE SET NULL;
