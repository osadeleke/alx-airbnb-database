<img width="1255" height="687" alt="image" src="https://github.com/user-attachments/assets/3771edd1-8e99-4f8f-805d-59b43bec9118" />

# Airbnb Database Normalization (Up to 3NF)

## Overview
This document explains how the **Airbnb database schema** was reviewed and refined to achieve **Third Normal Form (3NF)**, ensuring data consistency, eliminating redundancy, and improving integrity.

Normalization follows these key steps:

- **1NF:** Eliminate repeating groups and ensure atomic values.  
- **2NF:** Eliminate partial dependencies (every non-key attribute depends on the whole primary key).  
- **3NF:** Eliminate transitive dependencies (non-key attributes depend only on the key, not on other non-key attributes).

---

## 1. Review of the Original Design
The original schema was functionally correct but had some **potential normalization issues**:

| Issue | Description | Normalization Violation |
|-------|--------------|--------------------------|
| `location` field in `properties` | Combined multiple address-related data points into one string. | **1NF** |
| ENUM values like `role`, `status`, `payment_method` | Repeated text values across multiple rows; hard to update consistently. | **3NF** |
| `total_price` depends on property price | Could change when the host updates pricing; derived attribute without snapshot. | **3NF** |
| Lack of reference tables for roles, statuses, etc. | Causes update anomalies and duplicates of domain values. | **3NF** |

---

## 2. Normalization Steps

### Step 1 — Ensure Atomic Values (1NF)
**Problem:** `location` in `properties` stored multiple components (address, city, country) in one field.

**Fix:**
Split into atomic columns:
- `address_line1`
- `address_line2`
- `city`
- `state_region`
- `postal_code`
- `country_code`
- `latitude`, `longitude`

**Result:** Each column stores a single data item. Queries can now filter and index addresses efficiently.

---

### Step 2 — Eliminate Partial Dependencies (2NF)
**Context:** Partial dependencies occur in tables with composite primary keys.  
In this schema, every table uses a **single-column primary key (UUID)**, so no partial dependencies exist.

**Result:** The schema already satisfies **2NF**.

---

### Step 3 — Eliminate Transitive Dependencies (3NF)
**Problem:** Some non-key fields depended on other non-key fields rather than the table’s key.

**Fixes:**

#### a. Lookup Tables for ENUM Values
Created separate tables for **roles**, **booking_statuses**, and **payment_methods**.

| New Table | Old Column | Benefit |
|------------|-------------|----------|
| `roles` | `users.role` | Prevents typos and makes role names centrally managed |
| `booking_statuses` | `bookings.status` | Ensures consistent booking lifecycle states |
| `payment_methods` | `payments.payment_method` | Centralized control over payment types |

Each original column now references its respective lookup table via a foreign key (`role_code`, `status_code`, `method_code`).

**Result:** Non-key attributes now depend directly on the table’s primary key and not on arbitrary text values.

---

#### b. Snapshot Pricing in Bookings
**Problem:** `bookings.total_price` could change when `properties.price_per_night` changes.

**Fix:** Add fields:
- `nightly_price_at_booking`
- `currency`

These fields record the exact price when the booking was made.

**Result:** Each booking record is self-contained and historically accurate.  
No dependency on mutable property data.  

> **Note:** `total_price` is kept for performance but treated as a *derived attribute*. As long as it’s calculated and stored on write, it doesn’t violate 3NF.

---

#### c. Enforce Review Uniqueness
Added a **unique constraint** `(property_id, user_id)` in the `reviews` table.  
This prevents duplicate reviews by the same user for the same property.

**Result:** Data integrity improves without creating any new dependencies.

---

## 3. Summary of 3NF Compliance

| Table | Primary Key | Description of Normalization |
|--------|--------------|------------------------------|
| **roles** | `role_code` | Contains atomic data; all attributes depend on PK. |
| **booking_statuses** | `status_code` | One row per booking status; no transitive dependencies. |
| **payment_methods** | `method_code` | Each method uniquely identified; name depends on key. |
| **users** | `user_id` | Attributes depend only on `user_id`. `role_code` references `roles`. |
| **properties** | `property_id` | Address fields are atomic; `host_id` references `users`. |
| **bookings** | `booking_id` | Attributes depend only on `booking_id`; snapshot removes transitive dependency on property price. |
| **payments** | `payment_id` | All attributes depend on `payment_id`; `method_code` references `payment_methods`. |
| **reviews** | `review_id` | Each review depends on its key; optional unique constraint on `(property_id, user_id)`. |
| **messages** | `message_id` | Each message depends only on its key; no transitive dependencies. |

---

## 4. Justified Denormalization

Although strict normalization discourages derived attributes, one deliberate denormalization remains:

- `bookings.total_price` is stored instead of derived at runtime.
  - **Reason:** Improves query performance and ensures transactional integrity.
  - **Mitigation:** Compute and validate it during booking creation or update.

This design choice is **documented and controlled**, so it does not violate the principles of 3NF.

---

## 5. Conclusion

The updated model ensures:
- Each non-key attribute depends on **the key, the whole key, and nothing but the key**.
- Stable domain values (roles, statuses, payment methods) are stored in dedicated tables.
- All attributes are atomic and directly dependent on their primary key.

This design achieves **Third Normal Form (3NF)** while balancing **data integrity**, **scalability**, and **real-world performance needs**.
