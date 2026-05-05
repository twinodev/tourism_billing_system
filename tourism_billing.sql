-- ============================================================
--  TOURISM SECTOR FINANCIAL BILLING SYSTEM
--  Database: tourism_billing_db
--  Engine: MySQL 8.0 | InnoDB | utf8mb4
-- ============================================================

DROP DATABASE IF EXISTS tourism_billing_db;
CREATE DATABASE tourism_billing_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE tourism_billing_db;

-- ──────────────────────────────────────────────────────────
-- 1. CUSTOMERS
-- ──────────────────────────────────────────────────────────
CREATE TABLE customers (
  customer_id    INT AUTO_INCREMENT PRIMARY KEY,
  first_name     VARCHAR(50)  NOT NULL,
  last_name      VARCHAR(50)  NOT NULL,
  email          VARCHAR(100) NOT NULL UNIQUE,
  phone          VARCHAR(20)  NOT NULL,
  address        TEXT,
  nationality    VARCHAR(50),
  customer_type  ENUM('Individual','Corporate') DEFAULT 'Individual',
  created_at     DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ──────────────────────────────────────────────────────────
-- 2. AGENTS
-- ──────────────────────────────────────────────────────────
CREATE TABLE agents (
  agent_id       INT AUTO_INCREMENT PRIMARY KEY,
  agency_name    VARCHAR(100) NOT NULL,
  contact_person VARCHAR(100),
  email          VARCHAR(100) UNIQUE,
  phone          VARCHAR(20),
  commission_pct DECIMAL(5,2) DEFAULT 5.00,
  is_active      TINYINT(1)   DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ──────────────────────────────────────────────────────────
-- 3. STAFF  (recursive: supervisor_id -> staff_id)
-- ──────────────────────────────────────────────────────────
CREATE TABLE staff (
  staff_id       INT AUTO_INCREMENT PRIMARY KEY,
  first_name     VARCHAR(50)  NOT NULL,
  last_name      VARCHAR(50)  NOT NULL,
  role           VARCHAR(50)  NOT NULL,
  email          VARCHAR(100) UNIQUE,
  phone          VARCHAR(20),
  supervisor_id  INT,
  hired_date     DATE,
  FOREIGN KEY (supervisor_id) REFERENCES staff(staff_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ──────────────────────────────────────────────────────────
-- 4. SERVICES
-- ──────────────────────────────────────────────────────────
CREATE TABLE services (
  service_id    INT AUTO_INCREMENT PRIMARY KEY,
  service_name  VARCHAR(100) NOT NULL,
  service_type  ENUM('Accommodation','Tour','Transport','Meals','Other') NOT NULL,
  unit_price    DECIMAL(12,2) NOT NULL,
  unit          VARCHAR(30)   NOT NULL,
  description   TEXT,
  is_active     TINYINT(1)   DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ──────────────────────────────────────────────────────────
-- 5. PACKAGES
-- ──────────────────────────────────────────────────────────
CREATE TABLE packages (
  package_id    INT AUTO_INCREMENT PRIMARY KEY,
  package_name  VARCHAR(100) NOT NULL,
  description   TEXT,
  package_price DECIMAL(12,2) NOT NULL,
  duration_days INT           DEFAULT 1,
  is_active     TINYINT(1)   DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ──────────────────────────────────────────────────────────
-- 6. PACKAGE_SERVICES  (M:N junction: package <-> service)
-- ──────────────────────────────────────────────────────────
CREATE TABLE package_services (
  package_id  INT NOT NULL,
  service_id  INT NOT NULL,
  quantity    INT DEFAULT 1,
  PRIMARY KEY (package_id, service_id),
  FOREIGN KEY (package_id) REFERENCES packages(package_id) ON DELETE CASCADE,
  FOREIGN KEY (service_id) REFERENCES services(service_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ──────────────────────────────────────────────────────────
-- 7. BOOKINGS
-- ──────────────────────────────────────────────────────────
CREATE TABLE bookings (
  booking_id     INT AUTO_INCREMENT PRIMARY KEY,
  customer_id    INT  NOT NULL,
  agent_id       INT,
  booking_date   DATE NOT NULL,
  travel_date    DATE NOT NULL,
  end_date       DATE,
  total_persons  INT  DEFAULT 1,
  status         ENUM('Pending','Confirmed','Cancelled','Completed') DEFAULT 'Pending',
  notes          TEXT,
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE RESTRICT,
  FOREIGN KEY (agent_id)    REFERENCES agents(agent_id)       ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ──────────────────────────────────────────────────────────
-- 8. BOOKING_PACKAGES  (M:N junction: booking <-> package)
-- ──────────────────────────────────────────────────────────
CREATE TABLE booking_packages (
  booking_id  INT NOT NULL,
  package_id  INT NOT NULL,
  quantity    INT DEFAULT 1,
  PRIMARY KEY (booking_id, package_id),
  FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)  ON DELETE CASCADE,
  FOREIGN KEY (package_id) REFERENCES packages(package_id)  ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ──────────────────────────────────────────────────────────
-- 9. INVOICES
-- ──────────────────────────────────────────────────────────
CREATE TABLE invoices (
  invoice_id    INT AUTO_INCREMENT PRIMARY KEY,
  booking_id    INT  NOT NULL,
  invoice_date  DATE NOT NULL,
  due_date      DATE NOT NULL,
  subtotal      DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  tax_rate      DECIMAL(5,2)  NOT NULL DEFAULT 18.00,
  tax_amount    DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  total_amount  DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  amount_paid   DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  status        ENUM('Draft','Issued','Partially Paid','Paid','Overdue','Cancelled')
                DEFAULT 'Draft',
  FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ──────────────────────────────────────────────────────────
-- 10. INVOICE_ITEMS
-- ──────────────────────────────────────────────────────────
CREATE TABLE invoice_items (
  item_id       INT AUTO_INCREMENT PRIMARY KEY,
  invoice_id    INT           NOT NULL,
  service_id    INT           NOT NULL,
  description   VARCHAR(255),
  quantity      INT           NOT NULL DEFAULT 1,
  unit_price    DECIMAL(12,2) NOT NULL,
  line_total    DECIMAL(12,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
  FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id) ON DELETE CASCADE,
  FOREIGN KEY (service_id) REFERENCES services(service_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ──────────────────────────────────────────────────────────
-- 11. PAYMENTS
-- ──────────────────────────────────────────────────────────
CREATE TABLE payments (
  payment_id      INT AUTO_INCREMENT PRIMARY KEY,
  invoice_id      INT  NOT NULL,
  payment_date    DATE NOT NULL,
  amount          DECIMAL(12,2) NOT NULL,
  payment_method  ENUM('Cash','Mobile Money','Bank Transfer','Card','Cheque') NOT NULL,
  reference_no    VARCHAR(100),
  received_by     INT,
  notes           TEXT,
  FOREIGN KEY (invoice_id)  REFERENCES invoices(invoice_id) ON DELETE RESTRICT,
  FOREIGN KEY (received_by) REFERENCES staff(staff_id)      ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  DATA POPULATION
-- ============================================================

-- Customers
INSERT INTO customers (first_name, last_name, email, phone, nationality, customer_type) VALUES
('John',      'Mugisha',  'john.mugisha@gmail.com',      '+256701234567', 'Ugandan',    'Individual'),
('Sarah',     'Kamau',    'sarah.kamau@corp.ke',          '+254722345678', 'Kenyan',     'Corporate'),
('Michael',   'Osei',     'm.osei@accra.gh',              '+233241234567', 'Ghanaian',   'Individual'),
('Jennifer',  'Nakato',   'jennifer.n@yahoo.com',         '+256782345678', 'Ugandan',    'Individual'),
('Trans East Africa Ltd', 'Corp', 'billing@transea.com', '+255789012345', 'Tanzanian',  'Corporate'),
('Amara',     'Diallo',   'amara.diallo@gmail.com',       '+221771234567', 'Senegalese', 'Individual'),
('Linda',     'Chebet',   'l.chebet@kenyatech.co.ke',     '+254733445566', 'Kenyan',     'Corporate');

-- Agents
INSERT INTO agents (agency_name, contact_person, email, phone, commission_pct) VALUES
('Pearl of Africa Tours', 'Robert Kiggundu', 'robert@pearlofafrica.ug', '+256703000111', 8.00),
('Nile Safari Agents',    'Amina Hassan',    'amina@nilesafari.ug',     '+256772000222', 6.50),
('Great Lakes Travel',    'David Tumwine',   'dtumwine@greatlakes.ug',  '+256753000333', 7.00),
('Savanna Explorers',     'Rita Namukasa',   'rita@savanna.ug',         '+256702000444', 5.50);

-- Staff
INSERT INTO staff (first_name, last_name, role, email, phone, hired_date) VALUES
('Grace',   'Atuhaire',  'Finance Manager', 'g.atuhaire@tourco.ug', '+256701111001', '2021-03-15'),
('Patrick', 'Byamukama', 'Billing Clerk',   'p.bya@tourco.ug',      '+256701111002', '2022-07-01'),
('Esther',  'Nambooze',  'Billing Clerk',   'e.nambooze@tourco.ug', '+256701111003', '2023-01-20'),
('Samuel',  'Okello',    'System Admin',    's.okello@tourco.ug',   '+256701111004', '2020-09-10'),
('Brenda',  'Atim',      'Sales Executive', 'b.atim@tourco.ug',     '+256701111005', '2023-06-01');

-- Supervisors (Grace supervises Patrick, Esther, Brenda)
UPDATE staff SET supervisor_id = 1 WHERE staff_id IN (2, 3, 5);

-- Services
INSERT INTO services (service_name, service_type, unit_price, unit, description) VALUES
('Standard Room (per night)',       'Accommodation', 180000,  'per night',           'Standard double room with breakfast'),
('Deluxe Suite (per night)',        'Accommodation', 320000,  'per night',           'Deluxe suite with lake view and all meals'),
('Bwindi Gorilla Trekking',         'Tour',          700000,  'per person',          'Full-day gorilla trekking permit and guide'),
('Queen Elizabeth Game Drive',      'Tour',          250000,  'per person',          'Morning and afternoon game drives'),
('Airport Transfer (one way)',      'Transport',      80000,  'per trip',            'Entebbe Airport to city centre'),
('Safari Land Cruiser (day hire)',  'Transport',     450000,  'per day',             'Full-day 4x4 land cruiser hire with driver'),
('Full Board Meals Package',        'Meals',         120000,  'per person per day',  'Breakfast, lunch and dinner'),
('Murchison Falls Boat Cruise',     'Tour',          200000,  'per person',          'Boat cruise along the Nile to Murchison Falls'),
('Chimpanzee Tracking',             'Tour',          600000,  'per person',          'Kibale Forest chimpanzee tracking with guide'),
('Budget Hostel Bed',               'Accommodation',  65000,  'per night',           'Dormitory bed with shared facilities');

-- Packages
INSERT INTO packages (package_name, description, package_price, duration_days) VALUES
('Gorilla Discovery 3 Days',         '3-day package: accommodation + gorilla trekking + full board meals',        1800000, 3),
('Queen Elizabeth Explorer 4 Days',  '4-day safari: accommodation + game drives + meals + land cruiser',          2400000, 4),
('Murchison Falls Adventure 2 Days', '2-day adventure: accommodation + boat cruise + meals + airport transfer',   1100000, 2),
('Budget Uganda Explorer 5 Days',    '5-day budget: hostel + chimp tracking + meals + airport transfer',          1950000, 5);

-- Package_Services
INSERT INTO package_services (package_id, service_id, quantity) VALUES
-- Package 1: Gorilla Discovery
(1, 1, 3), (1, 3, 1), (1, 7, 3),
-- Package 2: Queen Elizabeth Explorer
(2, 1, 4), (2, 4, 2), (2, 6, 1), (2, 7, 4),
-- Package 3: Murchison Falls Adventure
(3, 1, 2), (3, 8, 1), (3, 7, 2), (3, 5, 2),
-- Package 4: Budget Explorer
(4, 10, 5), (4, 9, 1), (4, 7, 5), (4, 5, 2);

-- Bookings
INSERT INTO bookings (customer_id, agent_id, booking_date, travel_date, end_date, total_persons, status, notes) VALUES
(1, 1, '2025-10-01', '2025-11-10', '2025-11-13', 2, 'Confirmed', 'Honeymoon couple - special arrangement needed'),
(2, 2, '2025-10-05', '2025-11-20', '2025-11-24', 5, 'Confirmed', 'Corporate team-building retreat'),
(3, NULL,'2025-10-08', '2025-11-15', '2025-11-16', 1, 'Confirmed', 'Solo traveller, direct booking'),
(4, 3, '2025-10-12', '2025-12-01', '2025-12-05', 3, 'Pending',   'Awaiting deposit confirmation'),
(5, 2, '2025-10-18', '2025-12-10', '2025-12-14', 8, 'Confirmed', 'Corporate group - invoice to company'),
(6, 4, '2025-10-22', '2025-11-28', '2025-11-30', 2, 'Confirmed', NULL),
(7, 1, '2025-10-30', '2025-12-20', '2025-12-25', 4, 'Pending',   'VIP clients - request lake view rooms');

-- Booking_Packages (some bookings use packages)
INSERT INTO booking_packages (booking_id, package_id, quantity) VALUES
(1, 1, 1),  -- Booking 1 uses Gorilla Discovery x1
(2, 2, 1),  -- Booking 2 uses Queen Elizabeth Explorer x1
(5, 2, 1),  -- Booking 5 uses Queen Elizabeth Explorer x1
(6, 3, 1);  -- Booking 6 uses Murchison Falls Adventure x1

-- Invoices
INSERT INTO invoices (booking_id, invoice_date, due_date, subtotal, tax_rate, tax_amount, total_amount, amount_paid, status) VALUES
(1, '2025-10-01', '2025-10-31', 3600000,  18, 648000,   4248000,  4248000,  'Paid'),
(2, '2025-10-05', '2025-11-05', 12000000, 18, 2160000, 14160000,  7080000,  'Partially Paid'),
(3, '2025-10-08', '2025-11-08',  700000,  18, 126000,    826000,        0,  'Overdue'),
(4, '2025-10-12', '2025-11-12', 5400000,  18, 972000,   6372000,        0,  'Issued'),
(5, '2025-10-18', '2025-11-18', 9600000,  18, 1728000, 11328000,  5664000,  'Partially Paid'),
(6, '2025-10-22', '2025-11-22', 2200000,  18, 396000,   2596000,  2596000,  'Paid'),
(7, '2025-10-30', '2025-11-30', 7200000,  18, 1296000,  8496000,        0,  'Issued');

-- Invoice Items
INSERT INTO invoice_items (invoice_id, service_id, description, quantity, unit_price) VALUES
-- Invoice 1 (Booking 1 - Gorilla Discovery x2 persons)
(1, 1, 'Standard Room x2 persons x3 nights',    6, 180000),
(1, 7, 'Full Board Meals x2 persons x3 days',   6, 120000),
-- Invoice 2 (Booking 2 - Queen Elizabeth x5 persons)
(2, 2, 'Deluxe Suite x5 persons x4 nights',    20, 320000),
(2, 4, 'Game Drive x5 persons x2 sessions',    10, 250000),
(2, 6, 'Safari Land Cruiser x4 days',           4, 450000),
-- Invoice 3 (Booking 3 - Solo gorilla trek)
(3, 3, 'Gorilla Trekking Permit x1 person',     1, 700000),
-- Invoice 4 (Booking 4 - Family stay)
(4, 1, 'Standard Room x3 persons x4 nights',  12, 180000),
(4, 7, 'Full Board Meals x3 persons x4 days', 12, 120000),
(4, 5, 'Airport Transfer x2 (arrival + departure)', 2, 80000),
-- Invoice 5 (Booking 5 - Corporate group x8)
(5, 2, 'Deluxe Suite x8 persons x4 nights',   32, 320000),
-- Invoice 6 (Booking 6 - Murchison Falls x2)
(6, 1, 'Standard Room x2 persons x2 nights',   4, 180000),
(6, 8, 'Murchison Falls Boat Cruise x2',        2, 200000),
(6, 7, 'Full Board Meals x2 persons x2 days',  4, 120000),
(6, 5, 'Airport Transfer x2',                  2,  80000),
-- Invoice 7 (Booking 7 - VIP group x4)
(7, 2, 'Deluxe Suite x4 persons x5 nights',   20, 320000),
(7, 7, 'Full Board Meals x4 persons x5 days', 20, 120000);

-- Payments
INSERT INTO payments (invoice_id, payment_date, amount, payment_method, reference_no, received_by, notes) VALUES
(1, '2025-10-15', 4248000, 'Bank Transfer',  'TXN-KCB-20251015-001', 2, 'Full payment received'),
(2, '2025-10-20', 7080000, 'Mobile Money',   'MTN-MM-20251020-447',  3, '50% deposit'),
(5, '2025-10-25', 5664000, 'Bank Transfer',  'TXN-STD-20251025-332', 2, '50% deposit - corporate'),
(6, '2025-10-28', 2596000, 'Cash',           NULL,                   3, 'Cash payment in full');

-- ============================================================
--  USEFUL VIEWS
-- ============================================================

-- View 1: Customer Invoice Summary
CREATE VIEW vw_customer_invoices AS
SELECT
  c.customer_id,
  CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
  c.email, c.phone, c.customer_type,
  i.invoice_id, i.invoice_date, i.due_date,
  i.total_amount, i.amount_paid,
  (i.total_amount - i.amount_paid) AS balance_due,
  i.status AS invoice_status
FROM customers c
JOIN bookings b  ON b.customer_id = c.customer_id
JOIN invoices i  ON i.booking_id  = b.booking_id;

-- View 2: Invoice Line Items Detail
CREATE VIEW vw_invoice_detail AS
SELECT
  i.invoice_id,
  CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
  b.travel_date, b.end_date, b.total_persons,
  s.service_name, s.service_type,
  ii.description, ii.quantity, ii.unit_price, ii.line_total,
  i.subtotal, i.tax_rate, i.tax_amount, i.total_amount,
  i.amount_paid, (i.total_amount - i.amount_paid) AS balance_due,
  i.status
FROM invoices i
JOIN bookings b     ON i.booking_id   = b.booking_id
JOIN customers c    ON b.customer_id  = c.customer_id
JOIN invoice_items ii ON ii.invoice_id = i.invoice_id
JOIN services s     ON ii.service_id  = s.service_id;

-- View 3: Outstanding balances
CREATE VIEW vw_outstanding_balances AS
SELECT
  i.invoice_id,
  CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
  c.phone,
  i.due_date,
  i.total_amount,
  i.amount_paid,
  (i.total_amount - i.amount_paid) AS balance_due,
  i.status,
  DATEDIFF(CURDATE(), i.due_date) AS days_overdue
FROM invoices i
JOIN bookings b  ON i.booking_id  = b.booking_id
JOIN customers c ON b.customer_id = c.customer_id
WHERE i.amount_paid < i.total_amount
  AND i.status NOT IN ('Cancelled')
ORDER BY days_overdue DESC;
