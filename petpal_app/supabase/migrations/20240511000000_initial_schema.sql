-- Initial PetPal Database Schema
-- Execute as a single transaction
BEGIN;

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create schemas
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS storage;

-- Create storage buckets
INSERT INTO storage.buckets (id, name) VALUES ('petpal', 'Pet App Storage')
ON CONFLICT DO NOTHING;

-- Configure storage policies
CREATE POLICY "Public Read Access"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'petpal');

CREATE POLICY "Authenticated Upload Access"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'petpal' AND auth.role() = 'authenticated');

CREATE POLICY "Owner Update Delete Access"
  ON storage.objects FOR UPDATE
  USING (bucket_id = 'petpal' AND owner = auth.uid());

CREATE POLICY "Owner Delete Access"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'petpal' AND owner = auth.uid());

-- Create core tables

-- Users table (extends auth.users)
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  phone TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  subscription_tier TEXT DEFAULT 'free',
  settings JSONB DEFAULT '{}'
);

-- Households
CREATE TABLE households (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE
);

-- Household members
CREATE TABLE household_members (
  household_id UUID REFERENCES households(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('owner', 'caretaker', 'viewer', 'vet')),
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  display_name TEXT,
  avatar_url TEXT,
  PRIMARY KEY (household_id, user_id)
);

-- Pets
CREATE TABLE pets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  breed TEXT,
  gender TEXT,
  birthdate DATE,
  weight NUMERIC,
  microchip_id TEXT,
  profile_photo_url TEXT,
  notes TEXT,
  custom_fields JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  household_id UUID REFERENCES households(id) ON DELETE SET NULL,
  primary_vet_id UUID REFERENCES users(id) ON DELETE SET NULL
);

-- Pet media gallery
CREATE TABLE pet_media (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('photo', 'video', 'document')),
  caption TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE
);

-- Journal entries
CREATE TABLE journal_entries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
  entry_type TEXT NOT NULL CHECK (entry_type IN ('food', 'activity', 'health', 'mood', 'general')),
  food_data JSONB,
  activity_data JSONB,
  health_data JSONB,
  mood_data JSONB,
  notes TEXT,
  photo_urls TEXT[],
  tags TEXT[],
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_by UUID REFERENCES users(id) ON DELETE SET NULL
);

-- Reminders
CREATE TABLE reminders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pet_id UUID REFERENCES pets(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  reminder_type TEXT NOT NULL,
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE,
  recurrence_rule TEXT,
  completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMP WITH TIME ZONE,
  snooze_count INTEGER DEFAULT 0,
  assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data JSONB DEFAULT '{}'
);

-- Medications
CREATE TABLE medications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  dosage TEXT NOT NULL,
  frequency TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  notes TEXT,
  barcode TEXT,
  active BOOLEAN DEFAULT TRUE,
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Health records
CREATE TABLE health_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  record_type TEXT NOT NULL,
  date DATE NOT NULL,
  provider TEXT,
  notes TEXT,
  document_urls TEXT[],
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Weight records
CREATE TABLE weight_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  weight NUMERIC NOT NULL,
  date DATE NOT NULL,
  notes TEXT,
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Lost pets
CREATE TABLE lost_pets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'searching' CHECK (status IN ('searching', 'found')),
  reported_at TIMESTAMP WITH TIME ZONE NOT NULL,
  found_at TIMESTAMP WITH TIME ZONE,
  last_latitude NUMERIC,
  last_longitude NUMERIC,
  last_location_update TIMESTAMP WITH TIME ZONE,
  details TEXT,
  contact_info TEXT NOT NULL,
  reported_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  alert_radius NUMERIC DEFAULT 5.0,
  is_public BOOLEAN DEFAULT TRUE,
  notified_users UUID[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Products
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  price NUMERIC NOT NULL,
  discount_percent NUMERIC,
  rating NUMERIC,
  rating_count INTEGER,
  category TEXT NOT NULL,
  sub_category TEXT,
  for_pet_types TEXT[] NOT NULL,
  image_urls TEXT[] NOT NULL,
  is_featured BOOLEAN DEFAULT FALSE,
  is_best_seller BOOLEAN DEFAULT FALSE,
  is_new BOOLEAN DEFAULT FALSE,
  available_sizes TEXT[],
  available_colors TEXT[],
  stock INTEGER NOT NULL DEFAULT 0,
  brand TEXT NOT NULL,
  tags TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Orders
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
  total_amount NUMERIC NOT NULL,
  shipping_address JSONB NOT NULL,
  tracking_number TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Order items
CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL,
  price_at_purchase NUMERIC NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Chat messages
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  pet_id UUID REFERENCES pets(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  attachments JSONB DEFAULT '[]'
);

-- User subscriptions
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plan_id TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('active', 'canceled', 'expired')),
  started_at TIMESTAMP WITH TIME ZONE NOT NULL,
  expires_at TIMESTAMP WITH TIME ZONE,
  payment_provider TEXT NOT NULL,
  payment_data JSONB DEFAULT '{}'
);

-- Achievements
CREATE TABLE achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  pet_id UUID REFERENCES pets(id) ON DELETE CASCADE,
  achievement_code TEXT NOT NULL,
  unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data JSONB DEFAULT '{}'
);

-- Create RLS policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE households ENABLE ROW LEVEL SECURITY;
ALTER TABLE household_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE pets ENABLE ROW LEVEL SECURITY;
ALTER TABLE pet_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE weight_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE lost_pets ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;

-- Create indexes for performance
CREATE INDEX idx_pets_user_id ON pets(user_id);
CREATE INDEX idx_pets_household_id ON pets(household_id);
CREATE INDEX idx_household_members_user_id ON household_members(user_id);
CREATE INDEX idx_journal_entries_pet_id ON journal_entries(pet_id);
CREATE INDEX idx_journal_entries_timestamp ON journal_entries(timestamp);
CREATE INDEX idx_reminders_pet_id ON reminders(pet_id);
CREATE INDEX idx_reminders_start_time ON reminders(start_time);
CREATE INDEX idx_medications_pet_id ON medications(pet_id);
CREATE INDEX idx_health_records_pet_id ON health_records(pet_id);
CREATE INDEX idx_weight_records_pet_id ON weight_records(pet_id);
CREATE INDEX idx_lost_pets_pet_id ON lost_pets(pet_id);
CREATE INDEX idx_lost_pets_status ON lost_pets(status);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_messages_household_id ON messages(household_id);
CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_achievements_user_id ON achievements(user_id);

-- Add user policies
CREATE POLICY "Users can read their own data"
  ON users FOR SELECT
  USING (id = auth.uid());

CREATE POLICY "Users can update their own data"
  ON users FOR UPDATE
  USING (id = auth.uid());

-- Add household policies
CREATE POLICY "Users can read their own households"
  ON households FOR SELECT
  USING (id IN (
    SELECT household_id FROM household_members WHERE user_id = auth.uid()
  ) OR owner_id = auth.uid());

CREATE POLICY "Users can create households"
  ON households FOR INSERT
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY "Only owners can update households"
  ON households FOR UPDATE
  USING (owner_id = auth.uid());

CREATE POLICY "Only owners can delete households"
  ON households FOR DELETE
  USING (owner_id = auth.uid());

-- Add household member policies
CREATE POLICY "Users can read members of their households"
  ON household_members FOR SELECT
  USING (household_id IN (
    SELECT household_id FROM household_members WHERE user_id = auth.uid()
  ));

CREATE POLICY "Only household owners can manage members"
  ON household_members FOR INSERT
  WITH CHECK (household_id IN (
    SELECT id FROM households WHERE owner_id = auth.uid()
  ));

-- Add pet policies
CREATE POLICY "Users can read their pets and household pets"
  ON pets FOR SELECT
  USING (user_id = auth.uid() OR household_id IN (
    SELECT household_id FROM household_members WHERE user_id = auth.uid()
  ));

CREATE POLICY "Users can create pets"
  ON pets FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their pets"
  ON pets FOR UPDATE
  USING (user_id = auth.uid() OR household_id IN (
    SELECT household_id FROM household_members 
    WHERE user_id = auth.uid() AND role IN ('owner', 'caretaker')
  ));

CREATE POLICY "Users can delete their pets"
  ON pets FOR DELETE
  USING (user_id = auth.uid());

-- Add journal entry policies
CREATE POLICY "Users can read entries for their pets"
  ON journal_entries FOR SELECT
  USING (pet_id IN (
    SELECT id FROM pets WHERE user_id = auth.uid() OR household_id IN (
      SELECT household_id FROM household_members WHERE user_id = auth.uid()
    )
  ));

CREATE POLICY "Users can create entries for their pets"
  ON journal_entries FOR INSERT
  WITH CHECK (pet_id IN (
    SELECT id FROM pets WHERE user_id = auth.uid() OR household_id IN (
      SELECT household_id FROM household_members 
      WHERE user_id = auth.uid() AND role IN ('owner', 'caretaker')
    )
  ));

-- Add reminder policies
CREATE POLICY "Users can read reminders for their pets"
  ON reminders FOR SELECT
  USING (pet_id IN (
    SELECT id FROM pets WHERE user_id = auth.uid() OR household_id IN (
      SELECT household_id FROM household_members WHERE user_id = auth.uid()
    )
  ) OR created_by = auth.uid() OR assigned_to = auth.uid());

CREATE POLICY "Users can create reminders for their pets"
  ON reminders FOR INSERT
  WITH CHECK (pet_id IN (
    SELECT id FROM pets WHERE user_id = auth.uid() OR household_id IN (
      SELECT household_id FROM household_members 
      WHERE user_id = auth.uid() AND role IN ('owner', 'caretaker')
    )
  ));

-- Product policies
CREATE POLICY "Anyone can view products"
  ON products FOR SELECT
  USING (TRUE);

-- Create trigger functions for automatic timestamps
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at timestamps
CREATE TRIGGER set_updated_at_users
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at_households
  BEFORE UPDATE ON households
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at_pets
  BEFORE UPDATE ON pets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at_journal_entries
  BEFORE UPDATE ON journal_entries
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at_lost_pets
  BEFORE UPDATE ON lost_pets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at_products
  BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_updated_at_orders
  BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Trigger to update user profile when auth.users changes
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, display_name, avatar_url)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
    NEW.raw_user_meta_data->>'avatar_url'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Seed data for testing
-- Add test products
INSERT INTO products (name, description, price, category, for_pet_types, image_urls, brand, tags, is_featured, is_best_seller, is_new)
VALUES 
  ('Premium Dog Food', 'High-quality dog food with natural ingredients', 29.99, 'food', ARRAY['dog'], ARRAY['https://example.com/dogfood.jpg'], 'PetNutrition', ARRAY['food', 'dog', 'nutrition'], TRUE, TRUE, FALSE),
  ('Interactive Cat Toy', 'Electronic toy to keep your cat engaged', 19.99, 'toys', ARRAY['cat'], ARRAY['https://example.com/cattoy.jpg'], 'PlayPet', ARRAY['toys', 'cat', 'interactive'], FALSE, TRUE, TRUE),
  ('Dog Collar - Medium', 'Durable and comfortable collar for medium-sized dogs', 14.99, 'accessories', ARRAY['dog'], ARRAY['https://example.com/collar.jpg'], 'PetStyle', ARRAY['accessories', 'dog', 'collar'], TRUE, FALSE, FALSE),
  ('Pet Multivitamin', 'Daily supplements for overall pet health', 24.99, 'health', ARRAY['dog', 'cat'], ARRAY['https://example.com/vitamins.jpg'], 'PetHealth', ARRAY['health', 'supplements', 'vitamins'], FALSE, FALSE, TRUE),
  ('Self-Cleaning Litter Box', 'Automatic litter box for easy maintenance', 149.99, 'accessories', ARRAY['cat'], ARRAY['https://example.com/litterbox.jpg'], 'CleanPet', ARRAY['accessories', 'cat', 'litter'], TRUE, TRUE, TRUE);

COMMIT;