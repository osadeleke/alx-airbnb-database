# 🏡 Airbnb Database Schema (3NF - PostgreSQL)

This project defines a **fully normalized (3NF)** relational database schema for an Airbnb-like platform.  
It models users, properties, bookings, payments, reviews, and messages, with lookup tables for roles, booking statuses, and payment methods.

---

## 📋 Overview

The schema is designed using **PostgreSQL** and follows best practices in database normalization, integrity, and performance optimization.  
It includes:

- Clear **entity relationships** and **foreign key constraints**
- Support for **historical accuracy** (e.g., snapshot pricing)
- **Atomic** and **normalized** fields (3NF)
- Well-defined **indexes** for query efficiency

---

## 🧱 Database Entities

### 1. **roles**
Stores valid user roles.

| Column | Type | Description |
|--------|------|-------------|
| role_code | VARCHAR (PK) | `guest`, `host`, or `admin` |
| role_name | VARCHAR | Descriptive role name |

---

### 2. **booking_statuses**
Defines valid booking states.

| Column | Type | Description |
|--------|------|-------------|
| status_code | VARCHAR (PK) | `pending`, `confirmed`, `canceled` |
| status_name | VARCHAR | Descriptive label |

---

### 3. **payment_methods**
Defines valid payment types.

| Column | Type | Description |
|--------|------|-------------|
| method_code | VARCHAR (PK) | `credit_card`, `paypal`, `stripe` |
| method_name | VARCHAR | Descriptive label |

---

### 4. **users**
Represents both guests and hosts.

| Column | Type | Constraints |
|--------|------|-------------|
| user_id | UUID | Primary Key |
| first_name, last_name | VARCHAR | NOT NULL |
| email | VARCHAR | UNIQUE, NOT NULL |
| password_hash | VARCHAR | NOT NULL |
| phone_number | VARCHAR | Optional |
| role_code | FK → roles(role_code) | NOT NULL |
| created_at | TIMESTAMPTZ | Default CURRENT_TIMESTAMP |

**Indexes:**  
- `users_email_idx` on `(email)`

---

### 5. **properties**
Represents listings owned by hosts.

| Column | Type | Description |
|--------|------|-------------|
| property_id | UUID | Primary Key |
| host_id | FK → users(user_id) | Host who owns the property |
| name | VARCHAR | Property name |
| description | TEXT | Property details |
| address_line1 / address_line2 / city / country_code | VARCHAR | Structured address |
| price_per_night | NUMERIC(12,2) | Current nightly rate |
| created_at / updated_at | TIMESTAMPTZ | Timestamps |

**Indexes:**  
- `properties_host_idx`, `properties_city_idx`, `properties_country_idx`

---

### 6. **bookings**
Tracks user reservations.

| Column | Type | Description |
|--------|------|-------------|
| booking_id | UUID | Primary Key |
| property_id | FK → properties(property_id) | The booked property |
| user_id | FK → users(user_id) | The guest |
| start_date / end_date | DATE | Booking dates |
| nightly_price_at_booking | NUMERIC(12,2) | Snapshot price per night |
| currency | CHAR(3) | ISO 4217 currency code |
| total_price | NUMERIC(14,2) | Stored total (computed on write) |
| status_code | FK → booking_statuses(status_code) | Booking status |
| created_at | TIMESTAMPTZ | Default CURRENT_TIMESTAMP |

**Constraints:**
- `CHECK (end_date > start_date)`
- `CHECK (nightly_price_at_booking >= 0)`
- `CHECK (total_price >= 0)`

**Indexes:**  
- `bookings_property_idx`, `bookings_user_idx`, `bookings_status_idx`

---

### 7. **payments**
Tracks booking payments.

| Column | Type | Description |
|--------|------|-------------|
| payment_id | UUID | Primary Key |
| booking_id | FK → bookings(booking_id) | Linked booking |
| amount | NUMERIC(14,2) | Payment amount |
| currency | CHAR(3) | ISO 4217 currency |
| payment_date | TIMESTAMPTZ | Default CURRENT_TIMESTAMP |
| method_code | FK → payment_methods(method_code) | Payment method |

**Indexes:**  
- `payments_booking_idx`

---

### 8. **reviews**
Stores user reviews for properties.

| Column | Type | Description |
|--------|------|-------------|
| review_id | UUID | Primary Key |
| property_id | FK → properties(property_id) | Reviewed property |
| user_id | FK → users(user_id) | Reviewer |
| rating | INTEGER | 1–5 |
| comment | TEXT | Review text |
| created_at | TIMESTAMPTZ | Default CURRENT_TIMESTAMP |

**Constraints:**
- `CHECK (rating BETWEEN 1 AND 5)`
- `UNIQUE (property_id, user_id)` → One review per property per user

**Indexes:**  
- `reviews_property_idx`, `reviews_user_idx`

---

### 9. **messages**
Handles user-to-user messages.

| Column | Type | Description |
|--------|------|-------------|
| message_id | UUID | Primary Key |
| sender_id | FK → users(user_id) | Sender |
| recipient_id | FK → users(user_id) | Recipient |
| message_body | TEXT | Message content |
| sent_at | TIMESTAMPTZ | Default CURRENT_TIMESTAMP |

**Indexes:**  
- `messages_sender_idx`, `messages_recipient_idx`, `messages_sent_at_idx`

---

## 🔐 Normalization Summary (3NF)

| Principle | Applied Fix |
|------------|--------------|
| **1NF** | Split `location` into atomic address fields |
| **2NF** | No partial dependencies (all tables use UUID PKs) |
| **3NF** | Moved ENUM-like fields (`role`, `status`, `method`) to lookup tables |
| **3NF** | Added snapshot fields to `bookings` to avoid dependency on `properties` |
| **3NF** | Ensured all non-key attributes depend only on their table’s PK |

This ensures every non-key attribute depends **only on the key, the whole key, and nothing but the key.**

---

## ⚙️ Setup Instructions

### 1. Create Database
```sql
CREATE DATABASE airbnb_db;
\c airbnb_db;
```

## 2. Run Schema
Execute the provided SQL script:
```sql
\i airbnb_schema.sql
```

### 3. (Optional) Seed Lookup Tables
```sql
INSERT INTO roles(role_code, role_name) VALUES
  ('guest', 'Guest'),
  ('host', 'Host'),
  ('admin', 'Admin');

INSERT INTO booking_statuses(status_code, status_name) VALUES
  ('pending', 'Pending'),
  ('confirmed', 'Confirmed'),
  ('canceled', 'Canceled');

INSERT INTO payment_methods(method_code, method_name) VALUES
  ('credit_card', 'Credit Card'),
  ('paypal', 'PayPal'),
  ('stripe', 'Stripe');
```

---

## 🚀 Query Examples

**List all bookings by a given user**
```sql
SELECT b.*, p.name AS property_name
FROM bookings b
JOIN properties p ON b.property_id = p.property_id
WHERE b.user_id = '<user_uuid>';
```

**Calculate total host earnings**
```sql
SELECT u.first_name, u.last_name, SUM(b.total_price) AS total_earned
FROM users u
JOIN properties pr ON u.user_id = pr.host_id
JOIN bookings b ON pr.property_id = b.property_id
GROUP BY u.user_id;
```

**Get average property rating**
```sql
SELECT property_id, AVG(rating) AS avg_rating
FROM reviews
GROUP BY property_id;
```

---

## 📦 Technologies Used
- **Database:** PostgreSQL  
- **Normalization Level:** Third Normal Form (3NF)  
- **Keys & Constraints:** Primary keys (UUID), foreign keys, CHECKs, UNIQUEs  
- **Indexes:** Strategic indexing for performance on joins and searches

---

## 🧠 Notes
- `updated_at` should be managed via triggers if auto-update on modification is required.  
- `total_price` in `bookings` is a controlled denormalization for performance.  
- Consider using **PostGIS** for geospatial queries using `latitude` and `longitude`.  
- Extendable: add features like amenities, availability calendar, or multi-currency support.

---

## 🏁 Conclusion
This schema is:
- **Fully normalized (3NF)**
- **Relationally consistent**
- **Optimized for performance and data integrity**

It provides a solid foundation for building a scalable Airbnb-style application.
