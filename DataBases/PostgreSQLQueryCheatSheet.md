Absolutely. Here's a **comprehensive PostgreSQL query cheat sheet**, organized by topic. It includes real-world patterns and covers everything from basic SELECTs to JSONB, CTEs, window functions, and indexing.

---

# 🧠 PostgreSQL Query Cheat Sheet

---

## 🟩 Basics

```sql
-- Select all columns
SELECT * FROM table_name;

-- Select specific columns
SELECT id, username FROM users;

-- Limit and offset
SELECT * FROM logs LIMIT 100 OFFSET 200;
```

---

## 🔍 Filtering

```sql
-- WHERE clause
SELECT * FROM users WHERE age > 21;

-- BETWEEN
SELECT * FROM sales WHERE price BETWEEN 100 AND 500;

-- IN
SELECT * FROM users WHERE status IN ('active', 'pending');

-- IS NULL / IS NOT NULL
SELECT * FROM orders WHERE shipped_at IS NULL;

-- LIKE / ILIKE
SELECT * FROM products WHERE name ILIKE '%widget%';

-- NOT
SELECT * FROM users WHERE NOT active;
```

---

## 🔄 Sorting & Grouping

```sql
-- ORDER BY
SELECT * FROM users ORDER BY created_at DESC;

-- GROUP BY + aggregate
SELECT department, COUNT(*) FROM employees GROUP BY department;

-- HAVING
SELECT department, COUNT(*) FROM employees GROUP BY department HAVING COUNT(*) > 10;
```

---

## 🧮 Aggregations

```sql
SELECT
  COUNT(*) AS total,
  AVG(price) AS avg_price,
  SUM(quantity) AS total_sold,
  MAX(score) AS best_score,
  MIN(score) AS worst_score
FROM orders;
```

---

## 🧱 JOINs

```sql
-- INNER JOIN
SELECT u.name, o.total
FROM users u
JOIN orders o ON u.id = o.user_id;

-- LEFT JOIN
SELECT u.name, o.total
FROM users u
LEFT JOIN orders o ON u.id = o.user_id;

-- RIGHT JOIN
SELECT u.name, o.total
FROM users u
RIGHT JOIN orders o ON u.id = o.user_id;

-- FULL OUTER JOIN
SELECT u.name, o.total
FROM users u
FULL JOIN orders o ON u.id = o.user_id;

-- CROSS JOIN
SELECT * FROM products CROSS JOIN regions;
```

---

## 🧰 Subqueries

```sql
-- Scalar subquery
SELECT name FROM users WHERE id = (SELECT max(id) FROM users);

-- IN subquery
SELECT * FROM users WHERE id IN (SELECT user_id FROM orders);

-- EXISTS
SELECT * FROM users u WHERE EXISTS (
  SELECT 1 FROM orders o WHERE o.user_id = u.id
);
```

---

## 🪜 CTEs (WITH queries)

```sql
WITH recent_orders AS (
  SELECT * FROM orders WHERE created_at > now() - interval '30 days'
)
SELECT user_id, COUNT(*) FROM recent_orders GROUP BY user_id;
```

---

## 🪟 Window Functions

```sql
-- Running totals
SELECT
  id,
  user_id,
  total,
  SUM(total) OVER (PARTITION BY user_id ORDER BY created_at) AS running_total
FROM orders;

-- Row numbers
SELECT
  *,
  ROW_NUMBER() OVER (PARTITION BY category ORDER BY price DESC) AS rank
FROM products;
```

---

## 🧬 JSON / JSONB

```sql
-- Access JSON fields
SELECT data->'user'->>'email' AS email FROM events;

-- Filter by JSON field
SELECT * FROM logs WHERE data->>'status' = 'error';

-- Update JSON field
UPDATE logs SET data = jsonb_set(data, '{status}', '"fixed"') WHERE id = 42;
```

---

## 🔁 UPSERT / ON CONFLICT

```sql
INSERT INTO users (id, email)
VALUES (1, 'test@example.com')
ON CONFLICT (id) DO UPDATE SET email = EXCLUDED.email;
```

---

## 🧪 Pattern Matching

```sql
-- LIKE
SELECT * FROM emails WHERE address LIKE '%@gmail.com';

-- SIMILAR TO (regex-like)
SELECT * FROM logs WHERE path SIMILAR TO '%/(admin|login)%';

-- Regular expressions
SELECT * FROM users WHERE username ~ '^[a-z0-9_]+$'; -- case-sensitive
SELECT * FROM users WHERE username ~* 'admin';       -- case-insensitive
```

---

## 🔐 Permissions & Roles

```sql
-- List roles
\du

-- Grant read-only
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;

-- Create user
CREATE USER readonly_user WITH PASSWORD 'changeme';

-- Grant role
GRANT readonly_user TO app_user;
```

---

## 📋 Table Info & Schema

```sql
-- List tables
\dt

-- Describe table
\d users

-- List databases
\l

-- Show columns
SELECT column_name, data_type FROM information_schema.columns
WHERE table_name = 'users';
```

---

## ⚡ Indexing

```sql
-- Simple index
CREATE INDEX idx_users_email ON users(email);

-- Unique index
CREATE UNIQUE INDEX idx_unique_email ON users(email);

-- Partial index
CREATE INDEX idx_failed_logins ON logins(user_id)
WHERE success = false;

-- Expression index
CREATE INDEX idx_lower_email ON users(LOWER(email));
```

---

## 🗑️ Deletion & Truncation

```sql
DELETE FROM users WHERE last_login < now() - interval '1 year';

TRUNCATE TABLE temp_data;

TRUNCATE TABLE logs RESTART IDENTITY CASCADE;
```

---

## 🔄 Update

```sql
-- Simple update
UPDATE users SET last_login = now() WHERE id = 123;

-- Update using JOIN
UPDATE users u
SET email = e.new_email
FROM email_updates e
WHERE u.id = e.user_id;
```

---

## 🔍 Full Text Search

```sql
-- Basic search
SELECT * FROM articles
WHERE to_tsvector('english', content) @@ plainto_tsquery('english', 'security breach');

-- With ranking
SELECT *, ts_rank(to_tsvector(content), to_tsquery('threat')) AS rank
FROM articles
ORDER BY rank DESC;
```

---

## 🛠 Useful PSQL Shell Commands

```sql
-- Connect to DB
psql -U user -d dbname

-- List databases
\l

-- List schemas
\dn

-- List tables
\dt

-- Describe table
\d table_name

-- Execute SQL from file
\i /path/to/file.sql

-- Set output format
\x -- expanded
\a -- unaligned
\t -- tuples only
```

---

Would you like this exported as a `.sql`, `.txt`, or Markdown file for use in your tooling or reference?
