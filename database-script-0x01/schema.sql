-- =========================================================
-- Airbnb Schema (PostgreSQL) - 3NF Implementation
-- =========================================================

-- Optional: enable gen_random_uuid() if you want UUID defaults
-- CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================
-- Lookup / Reference tables
-- ============================

CREATE TABLE roles (
  role_code        VARCHAR PRIMARY KEY,             -- e.g., 'guest', 'host', 'admin'
  role_name        VARCHAR NOT NULL UNIQUE
);

CREATE TABLE booking_statuses (
  status_code      VARCHAR PRIMARY KEY,             -- e.g., 'pending', 'confirmed', 'canceled'
  status_name      VARCHAR NOT NULL UNIQUE
);

CREATE TABLE payment_methods (
  method_code      VARCHAR PRIMARY KEY,             -- e.g., 'credit_card', 'paypal', 'stripe'
  method_name      VARCHAR NOT NULL UNIQUE
);

-- ============================
-- Core entities
-- ============================

CREATE TABLE users (
  user_id          UUID PRIMARY KEY,
  first_name       VARCHAR NOT NULL,
  last_name        VARCHAR NOT NULL,
  email            VARCHAR NOT NULL UNIQUE,
  password_hash    VARCHAR NOT NULL,
  phone_number     VARCHAR,
  role_code        VARCHAR NOT NULL REFERENCES roles(role_code),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX users_email_idx ON users (email);

CREATE TABLE properties (
  property_id      UUID PRIMARY KEY,
  host_id          UUID NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
  name             VARCHAR NOT NULL,
  description      TEXT NOT NULL,

  -- Structured address (atomic; replaces ambiguous single 'location')
  address_line1    VARCHAR NOT NULL,
  address_line2    VARCHAR,
  city             VARCHAR NOT NULL,
  state_region     VARCHAR,
  postal_code      VARCHAR,
  country_code     VARCHAR NOT NULL,
  latitude         NUMERIC(10,6),
  longitude        NUMERIC(10,6),

  price_per_night  NUMERIC(12,2) NOT NULL CHECK (price_per_night >= 0),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
  -- NOTE: For automatic updated_at, add an update trigger (optional)
);

CREATE INDEX properties_host_idx    ON properties (host_id);
CREATE INDEX properties_city_idx    ON properties (city);
CREATE INDEX properties_country_idx ON properties (country_code);

CREATE TABLE bookings (
  booking_id               UUID PRIMARY KEY,
  property_id              UUID NOT NULL REFERENCES properties(property_id) ON DELETE CASCADE,
  user_id                  UUID NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT, -- guest
  start_date               DATE NOT NULL,
  end_date                 DATE NOT NULL,
  nightly_price_at_booking NUMERIC(12,2) NOT NULL CHECK (nightly_price_at_booking >= 0),
  currency                 CHAR(3) NOT NULL,  -- ISO 4217
  total_price              NUMERIC(14,2) NOT NULL CHECK (total_price >= 0),
  status_code              VARCHAR NOT NULL REFERENCES booking_statuses(status_code),
  created_at               TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT bookings_date_chk CHECK (end_date > start_date)
);

CREATE INDEX bookings_property_idx   ON bookings (property_id);
CREATE INDEX bookings_user_idx       ON bookings (user_id);
CREATE INDEX bookings_date_range_idx ON bookings (start_date, end_date);
CREATE INDEX bookings_status_idx     ON bookings (status_code);

CREATE TABLE payments (
  payment_id     UUID PRIMARY KEY,
  booking_id     UUID NOT NULL REFERENCES bookings(booking_id) ON DELETE CASCADE,
  amount         NUMERIC(14,2) NOT NULL CHECK (amount >= 0),
  currency       CHAR(3) NOT NULL, -- ISO 4217
  payment_date   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  method_code    VARCHAR NOT NULL REFERENCES payment_methods(method_code)
);

CREATE INDEX payments_booking_idx ON payments (booking_id);

CREATE TABLE reviews (
  review_id     UUID PRIMARY KEY,
  property_id   UUID NOT NULL REFERENCES properties(property_id) ON DELETE CASCADE,
  user_id       UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  rating        INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment       TEXT NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT reviews_user_property_unique UNIQUE (property_id, user_id)
  -- If business rule is "one review per booking", add booking_id FK and unique(booking_id) instead.
);

CREATE INDEX reviews_property_idx ON reviews (property_id);
CREATE INDEX reviews_user_idx     ON reviews (user_id);

CREATE TABLE messages (
  message_id    UUID PRIMARY KEY,
  sender_id     UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  recipient_id  UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  message_body  TEXT NOT NULL,
  sent_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX messages_sender_idx    ON messages (sender_id);
CREATE INDEX messages_recipient_idx ON messages (recipient_id);
CREATE INDEX messages_sent_at_idx   ON messages (sent_at);
