-- =============================================================
-- Airbnb Sample Data Population Script (PostgreSQL)
-- =============================================================
-- This script assumes the 3NF Airbnb schema already exists.
-- Run after creating all tables.

-- =============================================================
-- 1. Lookup Tables
-- =============================================================

INSERT INTO roles (role_code, role_name) VALUES
  ('guest', 'Guest'),
  ('host', 'Host'),
  ('admin', 'Admin');

INSERT INTO booking_statuses (status_code, status_name) VALUES
  ('pending', 'Pending'),
  ('confirmed', 'Confirmed'),
  ('canceled', 'Canceled');

INSERT INTO payment_methods (method_code, method_name) VALUES
  ('credit_card', 'Credit Card'),
  ('paypal', 'PayPal'),
  ('stripe', 'Stripe');

-- =============================================================
-- 2. Users (Guests and Hosts)
-- =============================================================

INSERT INTO users (user_id, first_name, last_name, email, password_hash, phone_number, role_code, created_at)
VALUES
  ('b1f7e32d-8f3b-4f4e-9e80-aaa111111111', 'Alice', 'Wong', 'alice@example.com', 'hash_pw1', '+1555000001', 'host', CURRENT_TIMESTAMP),
  ('c2f8e33d-7b4b-4b5f-9e81-bbb222222222', 'Bob', 'Martinez', 'bob@example.com', 'hash_pw2', '+1555000002', 'guest', CURRENT_TIMESTAMP),
  ('d3f9e34d-6c5c-4c6f-9e82-ccc333333333', 'Charlie', 'Smith', 'charlie@example.com', 'hash_pw3', '+1555000003', 'guest', CURRENT_TIMESTAMP),
  ('e4f0e35d-5d6d-4d7f-9e83-ddd444444444', 'Diana', 'Lopez', 'diana@example.com', 'hash_pw4', '+1555000004', 'host', CURRENT_TIMESTAMP),
  ('f5f1e36d-4e7e-4e8f-9e84-eee555555555', 'Evan', 'Brooks', 'evan@example.com', 'hash_pw5', '+1555000005', 'admin', CURRENT_TIMESTAMP);

-- =============================================================
-- 3. Properties
-- =============================================================

INSERT INTO properties (
  property_id, host_id, name, description,
  address_line1, address_line2, city, state_region, postal_code, country_code,
  latitude, longitude, price_per_night, created_at, updated_at
) VALUES
  ('a1111111-1111-1111-1111-111111111111', 'b1f7e32d-8f3b-4f4e-9e80-aaa111111111',
   'Cozy Mountain Cabin', 'A peaceful retreat in the mountains with a hot tub and a stunning view.',
   '123 Forest Trail', NULL, 'Aspen', 'CO', '81611', 'US',
   39.1911, -106.8175, 250.00, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

  ('a2222222-2222-2222-2222-222222222222', 'diana@example.com'::uuid, -- intentional fix below
   'Beachfront Villa', 'Luxury villa with private pool, Wi-Fi, and ocean views.',
   '789 Ocean Drive', NULL, 'Miami', 'FL', '33139', 'US',
   25.7907, -80.1300, 450.00, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

  ('a3333333-3333-3333-3333-333333333333', 'b1f7e32d-8f3b-4f4e-9e80-aaa111111111',
   'Downtown Apartment', 'Modern 2-bedroom apartment near shopping and restaurants.',
   '456 Market Street', 'Unit 12B', 'San Francisco', 'CA', '94103', 'US',
   37.7749, -122.4194, 190.00, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Oops, fix for diana host reference (must use her UUID)
UPDATE properties
SET host_id = 'e4f0e35d-5d6d-4d7f-9e83-ddd444444444'
WHERE property_id = 'a2222222-2222-2222-2222-222222222222';

-- =============================================================
-- 4. Bookings
-- =============================================================

INSERT INTO bookings (
  booking_id, property_id, user_id, start_date, end_date,
  nightly_price_at_booking, currency, total_price, status_code, created_at
) VALUES
  ('b0000000-0000-0000-0000-000000000001', 'a1111111-1111-1111-1111-111111111111',
   'c2f8e33d-7b4b-4b5f-9e81-bbb222222222', '2025-12-20', '2025-12-25', 250.00, 'USD', 1250.00, 'confirmed', CURRENT_TIMESTAMP),

  ('b0000000-0000-0000-0000-000000000002', 'a3333333-3333-3333-3333-333333333333',
   'd3f9e34d-6c5c-4c6f-9e82-ccc333333333', '2025-11-15', '2025-11-18', 190.00, 'USD', 570.00, 'confirmed', CURRENT_TIMESTAMP),

  ('b0000000-0000-0000-0000-000000000003', 'a2222222-2222-2222-2222-222222222222',
   'c2f8e33d-7b4b-4b5f-9e81-bbb222222222', '2026-01-10', '2026-01-15', 450.00, 'USD', 2250.00, 'pending', CURRENT_TIMESTAMP);

-- =============================================================
-- 5. Payments
-- =============================================================

INSERT INTO payments (
  payment_id, booking_id, amount, currency, payment_date, method_code
) VALUES
  ('p0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 1250.00, 'USD', CURRENT_TIMESTAMP, 'credit_card'),
  ('p0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000002', 570.00, 'USD', CURRENT_TIMESTAMP, 'paypal');

-- No payment yet for the pending booking.

-- =============================================================
-- 6. Reviews
-- =============================================================

INSERT INTO reviews (
  review_id, property_id, user_id, rating, comment, created_at
) VALUES
  ('r0000000-0000-0000-0000-000000000001', 'a1111111-1111-1111-1111-111111111111',
   'c2f8e33d-7b4b-4b5f-9e81-bbb222222222', 5,
   'Amazing stay! The cabin was clean and cozy with incredible views.', CURRENT_TIMESTAMP),

  ('r0000000-0000-0000-0000-000000000002', 'a3333333-3333-3333-3333-333333333333',
   'd3f9e34d-6c5c-4c6f-9e82-ccc333333333', 4,
   'Great location and stylish decor. Slight noise from the street but otherwise perfect.', CURRENT_TIMESTAMP);

-- =============================================================
-- 7. Messages
-- =============================================================

INSERT INTO messages (
  message_id, sender_id, recipient_id, message_body, sent_at
) VALUES
  ('m0000000-0000-0000-0000-000000000001',
   'c2f8e33d-7b4b-4b5f-9e81-bbb222222222', 'b1f7e32d-8f3b-4f4e-9e80-aaa111111111',
   'Hi Alice, I just booked your cabin for December! Looking forward to it.', CURRENT_TIMESTAMP),

  ('m0000000-0000-0000-0000-000000000002',
   'b1f7e32d-8f3b-4f4e-9e80-aaa111111111', 'c2f8e33d-7b4b-4b5f-9e81-bbb222222222',
   'Thanks Bob! I’ll send you check-in instructions closer to your arrival.', CURRENT_TIMESTAMP),

  ('m0000000-0000-0000-0000-000000000003',
   'd3f9e34d-6c5c-4c6f-9e82-ccc333333333', 'e4f0e35d-5d6d-4d7f-9e83-ddd444444444',
   'Hi Diana, is your villa available in February?', CURRENT_TIMESTAMP);

-- =============================================================
-- ✅ Data Population Complete
-- =============================================================

-- Quick sanity checks:
-- SELECT * FROM users;
-- SELECT * FROM properties;
-- SELECT * FROM bookings;
-- SELECT * FROM payments;
-- SELECT * FROM reviews;
-- SELECT * FROM messages;
