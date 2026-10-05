-- Supabase SQL Schema for Lahore Unified Transit App

-- Note: Ensure this is executed in your Supabase SQL editor.
-- This schema establishes the single source of truth for all agents working on the project.

-- 1. Profiles (Extends auth.users)
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  name TEXT,
  phone TEXT,
  role TEXT DEFAULT 'citizen' CHECK (role IN ('citizen', 'student', 'conductor', 'admin')),
  student_verified BOOLEAN DEFAULT false,
  device_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);

-- 2. Wallets
CREATE TABLE public.wallets (
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE PRIMARY KEY,
  balance DECIMAL(10, 2) DEFAULT 0.00,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);

-- 3. Transactions
CREATE TABLE public.transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT CHECK (type IN ('topup', 'deduction')),
  amount DECIMAL(10, 2) NOT NULL,
  method TEXT CHECK (method IN ('raast', 'jazzcash', 'qr_scan', 'admin')),
  status TEXT DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);

-- 4. Routes (Speedo, Metrobus, Orange Line)
CREATE TABLE public.routes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  network TEXT CHECK (network IN ('speedo', 'metro', 'orange')),
  name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);

-- 5. Stops (Nodes in the transit graph)
CREATE TABLE public.stops (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  route_id UUID REFERENCES public.routes(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  lat DOUBLE PRECISION NOT NULL,
  lng DOUBLE PRECISION NOT NULL,
  seq INTEGER NOT NULL, -- The order of the stop on the route
  is_interchange BOOLEAN DEFAULT false
);

-- 6. Fares (Configurable base fares)
CREATE TABLE public.fares (
  network TEXT PRIMARY KEY CHECK (network IN ('speedo', 'metro', 'orange')),
  base_fare DECIMAL(10, 2) NOT NULL,
  per_stop_fare DECIMAL(10, 2) DEFAULT 0.00
);

-- 7. Vehicles (Live Data)
CREATE TABLE public.vehicles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  route_id UUID REFERENCES public.routes(id) ON DELETE CASCADE,
  lat DOUBLE PRECISION NOT NULL,
  lng DOUBLE PRECISION NOT NULL,
  heading DOUBLE PRECISION DEFAULT 0.0,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);

-- 8. Tickets (Dynamic QR generated on device)
CREATE TABLE public.tickets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  qr_token TEXT UNIQUE NOT NULL,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  is_student BOOLEAN DEFAULT false,
  used BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);

-- 9. Student Verifications (OCR + Liveness)
CREATE TABLE public.student_verifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  card_url TEXT NOT NULL,
  selfie_url TEXT NOT NULL,
  ocr_json JSONB,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);

-- --------------------------------------------------------
-- Realtime Subscriptions
-- --------------------------------------------------------
-- Enable Realtime for Vehicles so the Map UI can track them live
ALTER PUBLICATION supabase_realtime ADD TABLE public.vehicles;

-- --------------------------------------------------------
-- Row Level Security (RLS) Policies
-- --------------------------------------------------------

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fares ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_verifications ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can read and update their own profiles
CREATE POLICY "Users can read own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Wallets: Users can view their own wallet
CREATE POLICY "Users can view own wallet" ON public.wallets FOR SELECT USING (auth.uid() = user_id);

-- Transactions: Users can view their own transactions
CREATE POLICY "Users can view own transactions" ON public.transactions FOR SELECT USING (auth.uid() = user_id);
-- Insert via Edge Function or secure client
CREATE POLICY "Users can insert own transactions" ON public.transactions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Routes, Stops, Fares: Public read access for everyone
CREATE POLICY "Public can read routes" ON public.routes FOR SELECT USING (true);
CREATE POLICY "Public can read stops" ON public.stops FOR SELECT USING (true);
CREATE POLICY "Public can read fares" ON public.fares FOR SELECT USING (true);

-- Vehicles: Public read access
CREATE POLICY "Public can track vehicles" ON public.vehicles FOR SELECT USING (true);
-- Updates to vehicles should ideally be restricted to service roles/Edge Functions

-- Tickets: Users can read and create their own tickets
CREATE POLICY "Users can view own tickets" ON public.tickets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own tickets" ON public.tickets FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Student Verifications: Users can read and create their own verifications
CREATE POLICY "Users can view own verifications" ON public.student_verifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own verifications" ON public.student_verifications FOR INSERT WITH CHECK (auth.uid() = user_id);

-- --------------------------------------------------------
-- Helper Functions & Triggers
-- --------------------------------------------------------

-- Trigger to automatically create a profile and wallet when a user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id)
  VALUES (new.id);
  
  INSERT INTO public.wallets (user_id, balance)
  VALUES (new.id, 0.00);
  
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
