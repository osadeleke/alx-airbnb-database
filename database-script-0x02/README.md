# 🏡 Airbnb Database Sample Data (PostgreSQL)

This project provides a **PostgreSQL database schema** and **sample data** for an Airbnb-like application.  
The schema is fully normalized to **Third Normal Form (3NF)** and includes realistic seed data for users, properties, bookings, payments, reviews, and messages.

---

## 📘 Overview

The database models a simplified Airbnb ecosystem with the following entities:

- **Users:** Guests, hosts, and admins  
- **Properties:** Listings created by hosts  
- **Bookings:** Reservations made by guests  
- **Payments:** Payments linked to bookings  
- **Reviews:** User feedback for properties  
- **Messages:** Conversations between users  
- **Lookup tables:** Roles, booking statuses, and payment methods

The design follows 3NF to minimize redundancy and maintain integrity.

---

## 🧩 Prerequisites

- PostgreSQL 13 or later
- `pgcrypto` extension (optional for UUID generation)

Enable the extension (if not already enabled):
```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;
```

---

## ⚙️ Setup Instructions

### Insert Sample Data
Execute the data population script:
```sql
\i seed.sql
```

This adds realistic example data for:
- Multiple hosts and guests  
- Properties in different cities  
- Confirmed and pending bookings  
- Payments using multiple methods  
- Reviews and inter-user messages

---

## 🧱 Schema Entities

| Entity | Description |
|---------|--------------|
| **roles** | Defines user roles (`guest`, `host`, `admin`). |
| **booking_statuses** | Defines valid booking states (`pending`, `confirmed`, `canceled`). |
| **payment_methods** | Defines valid payment types (`credit_card`, `paypal`, `stripe`). |
| **users** | Stores user details and references `roles`. |
| **properties** | Represents listings owned by hosts with structured address fields. |
| **bookings** | Records reservations and snapshot pricing. |
| **payments** | Links booking payments with amounts and methods. |
| **reviews** | Contains user reviews with ratings (1–5). |
| **messages** | Stores user-to-user messages (guest ↔ host). |

---

## 💾 Example Data Highlights

### 👤 Users
| Name | Role | Email |
|------|------|-------|
| Alice Wong | Host | alice@example.com |
| Diana Lopez | Host | diana@example.com |
| Bob Martinez | Guest | bob@example.com |
| Charlie Smith | Guest | charlie@example.com |
| Evan Brooks | Admin | evan@example.com |

---

### 🏠 Properties
| Name | City | Price/Night |
|------|------|--------------|
| Cozy Mountain Cabin | Aspen | $250 |
| Beachfront Villa | Miami | $450 |
| Downtown Apartment | San Francisco | $190 |

---

### 📅 Bookings
| Guest | Property | Status | Total |
|--------|-----------|--------|--------|
| Bob Martinez | Cozy Mountain Cabin | Confirmed | $1,250 |
| Charlie Smith | Downtown Apartment | Confirmed | $570 |
| Bob Martinez | Beachfront Villa | Pending | $2,250 |

---

### 💳 Payments
| Booking | Method | Amount |
|----------|---------|---------|
| Cozy Mountain Cabin | Credit Card | $1,250 |
| Downtown Apartment | PayPal | $570 |

---

### ⭐ Reviews
| Property | User | Rating | Comment |
|-----------|------|---------|----------|
| Cozy Mountain Cabin | Bob Martinez | 5 | “Amazing stay! Clean and cozy with stunning views.” |
| Downtown Apartment | Charlie Smith | 4 | “Great location, stylish decor, slight street noise.” |

---

### 💬 Messages
| Sender | Recipient | Message |
|---------|------------|----------|
| Bob → Alice | “Hi Alice, I just booked your cabin for December!” |
| Alice → Bob | “Thanks Bob! I’ll send check-in instructions soon.” |
| Charlie → Diana | “Hi Diana, is your villa available in February?” |

---

## 🧠 Normalization Summary

| Normal Form | Ensured By |
|--------------|------------|
| **1NF** | All columns store atomic data (no repeating groups). |
| **2NF** | Every table uses a single primary key (UUID). |
| **3NF** | Non-key attributes depend only on their table’s PK. Lookup tables remove transitive dependencies. |

---

## 🔍 Query Examples

### Get All Active Bookings for a User
```sql
SELECT b.booking_id, p.name AS property_name, b.start_date, b.end_date, b.total_price, b.status_code
FROM bookings b
JOIN properties p ON b.property_id = p.property_id
WHERE b.user_id = 'c2f8e33d-7b4b-4b5f-9e81-bbb222222222';
```

### Get Average Rating per Property
```sql
SELECT p.name, AVG(r.rating) AS average_rating
FROM reviews r
JOIN properties p ON r.property_id = p.property_id
GROUP BY p.name;
```

### Get Total Revenue per Host
```sql
SELECT u.first_name, u.last_name, SUM(b.total_price) AS total_revenue
FROM users u
JOIN properties pr ON u.user_id = pr.host_id
JOIN bookings b ON pr.property_id = b.property_id
WHERE b.status_code = 'confirmed'
GROUP BY u.first_name, u.last_name;
```

---

## 🧮 Key Features

- **3NF Normalization:** No redundant data; consistent relationships.  
- **Referential Integrity:** Strong FK relationships.  
- **Snapshot Bookings:** Preserves pricing history.  
- **Indexes:** Optimized for search and reporting queries.  
- **Scalability:** Easily extendable with amenities, availability, etc.

---

## 🚀 Optional Enhancements

- Add triggers to auto-update `updated_at` timestamps.
- Integrate PostGIS for geolocation support (`latitude`, `longitude`).
- Add audit logging or soft-delete flags (`deleted_at`).
- Introduce multi-currency support with exchange rate table.

---

## ✅ Summary

This database:
- Follows **Third Normal Form (3NF)**.
- Demonstrates **real-world Airbnb logic**.
- Includes **sample data** for easy testing.

Use this schema to:
- Learn relational modeling and normalization.
- Prototype booking and hosting apps.
- Test analytics or SQL query optimization.

---

**Author:** Your Name  
**Database:** PostgreSQL 13+  
**Version:** 1.0.0  
**License:** MIT
