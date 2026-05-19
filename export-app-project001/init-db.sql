-- =======================================================================================
-- DATABASE ARCHITECTURE - POSTGRESQL SQL SCRIPT
-- Collaborative Export Operations & Stuffing Heatmap Calendar Platform
-- =======================================================================================

-- Enable UUID extension if not already enabled (standard in Supabase)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ---------------------------------------------------------------------------------------
-- ENUMS
-- ---------------------------------------------------------------------------------------
CREATE TYPE user_role AS ENUM (
    'management', 
    'sales', 
    'prod_staff', 
    'warehouse_staff', 
    'shipping_staff', 
    'customer'
);

CREATE TYPE booking_status_enum AS ENUM (
    'planned', 
    'requested', 
    'confirmed', 
    'cancelled'
);

-- ---------------------------------------------------------------------------------------
-- TABLES
-- ---------------------------------------------------------------------------------------

-- 1. users
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    role user_role NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. customers
CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_name VARCHAR(255) NOT NULL,
    contact_email VARCHAR(255),
    sales_owner_id UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. purchase_orders
CREATE TABLE purchase_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    po_number VARCHAR(100) UNIQUE NOT NULL,
    customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
    total_ordered_quantity_mt DECIMAL(12, 2) NOT NULL,
    unit_price DECIMAL(12, 2) NOT NULL,
    total_value DECIMAL(15, 2) GENERATED ALWAYS AS (total_ordered_quantity_mt * unit_price) STORED,
    currency VARCHAR(10) DEFAULT 'USD',
    contract_file_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. products
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_code VARCHAR(50) UNIQUE NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    category VARCHAR(100)
);

-- 5. product_specifications
CREATE TABLE product_specifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    spec_code VARCHAR(100) UNIQUE NOT NULL,
    starch_min_pct DECIMAL(5, 2),
    moisture_max_pct DECIMAL(5, 2),
    sand_silica_max_pct DECIMAL(5, 2),
    fiber_max_pct DECIMAL(5, 2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 6. packaging_configurations
CREATE TABLE packaging_configurations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    config_code VARCHAR(100) UNIQUE NOT NULL,
    container_size VARCHAR(50),
    packaging_type VARCHAR(100),
    unit_weight_kg DECIMAL(10, 2),
    bag_quantity_per_container INTEGER,
    standard_payload_mt DECIMAL(10, 2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 7. shipments
CREATE TABLE shipments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    po_id UUID REFERENCES purchase_orders(id) ON DELETE CASCADE,
    di_number VARCHAR(100) UNIQUE NOT NULL,
    status SMALLINT NOT NULL CHECK (status >= 1 AND status <= 8),
    product_spec_id UUID REFERENCES product_specifications(id) ON DELETE RESTRICT,
    packaging_config_id UUID REFERENCES packaging_configurations(id) ON DELETE RESTRICT,
    container_count INTEGER NOT NULL,
    total_net_weight DECIMAL(12, 2),
    port_of_loading VARCHAR(255),
    port_of_discharge VARCHAR(255),
    vessel_voyage VARCHAR(255),
    etd_date DATE,
    eta_date DATE,
    stuffing_date DATE,
    booking_status booking_status_enum DEFAULT 'planned',
    booking_number VARCHAR(100),
    booking_expiry_date DATE,
    carrier_name VARCHAR(255),
    actual_starch_pct DECIMAL(5, 2),
    actual_moisture_pct DECIMAL(5, 2),
    coa_file_url TEXT,
    has_issue BOOLEAN DEFAULT FALSE,
    issue_description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 8. shipment_containers
CREATE TABLE shipment_containers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shipment_id UUID REFERENCES shipments(id) ON DELETE CASCADE,
    container_number VARCHAR(50) NOT NULL,
    seal_number VARCHAR(50),
    actual_net_weight_mt DECIMAL(10, 2),
    container_photo_url TEXT,
    stuffed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (shipment_id, container_number)
);

-- 9. shipment_status_history
CREATE TABLE shipment_status_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shipment_id UUID REFERENCES shipments(id) ON DELETE CASCADE,
    from_status SMALLINT CHECK (from_status >= 1 AND from_status <= 8),
    to_status SMALLINT NOT NULL CHECK (to_status >= 1 AND to_status <= 8),
    changed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------------------------
-- SEED DATA
-- ---------------------------------------------------------------------------------------

-- Store UUIDs in CTEs to link related rows elegantly
WITH new_product AS (
    INSERT INTO products (id, product_code, product_name, category)
    VALUES (gen_random_uuid(), 'THP-01', 'Tapioca Hard Pellet', 'Agricultural Bulk')
    RETURNING id
),
new_spec AS (
    INSERT INTO product_specifications (id, product_id, spec_code, starch_min_pct, moisture_max_pct, sand_silica_max_pct, fiber_max_pct)
    SELECT gen_random_uuid(), id, 'THP-PREMIUM-01', 68.00, 14.00, 3.00, 5.00 FROM new_product
    RETURNING id
)
SELECT * FROM new_spec;

INSERT INTO packaging_configurations (id, config_code, container_size, packaging_type, unit_weight_kg, bag_quantity_per_container, standard_payload_mt)
VALUES (
    gen_random_uuid(), 
    '20FT-JUMBO-950', 
    '20ft', 
    'Jumbo Bag', 
    950.00, 
    20, 
    19.00
);
