-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enum for shipment status
CREATE TYPE shipment_status AS ENUM (
  'pending_production', 
  'pending_packaging', 
  'awaiting_loading', 
  'loaded_into_container', 
  'awaiting_bl_confirmation', 
  'awaiting_all_docs', 
  'etd', 
  'eta'
);

-- Profiles
CREATE TABLE profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  company_name TEXT NOT NULL,
  role TEXT CHECK (role IN ('admin', 'customer')) DEFAULT 'customer'
);

-- Purchase Orders
CREATE TABLE purchase_orders (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  po_number TEXT UNIQUE NOT NULL,
  customer_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  contract_details TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Shipments
CREATE TABLE shipments (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  po_id UUID REFERENCES purchase_orders(id) ON DELETE CASCADE NOT NULL,
  di_number TEXT NOT NULL,
  status shipment_status DEFAULT 'pending_production',
  container_no TEXT,
  seal_no TEXT,
  etd_date DATE,
  eta_date DATE,
  bl_draft_url TEXT,
  all_docs_url TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE shipments ENABLE ROW LEVEL SECURITY;

-- Policies (Simplified for now - can be refined)
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Admins can view all POs" ON purchase_orders FOR SELECT USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Customers can view own POs" ON purchase_orders FOR SELECT USING (customer_id = auth.uid());
CREATE POLICY "Admins can view all shipments" ON shipments FOR SELECT USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Customers can view associated shipments" ON shipments FOR SELECT USING (EXISTS (SELECT 1 FROM purchase_orders WHERE id = shipments.po_id AND customer_id = auth.uid()));
