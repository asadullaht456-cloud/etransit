# Lahore Unified Transit App: Implementation Plan

## 1. Folder Structure (Expo Router + TypeScript)

```text
/
├── app/                      # Expo Router screens and API routes
│   ├── (auth)/               # Authentication flow
│   │   ├── login.tsx
│   │   └── signup.tsx
│   ├── (tabs)/               # Main navigation tabs
│   │   ├── _layout.tsx       # Bottom tab navigator
│   │   ├── index.tsx         # Home (Map + Search + Bottom Sheet)
│   │   ├── wallet.tsx        # Wallet & Transactions
│   │   ├── pass.tsx          # My QR Pass
│   │   └── profile.tsx       # Profile / Settings
│   ├── student/              # Student verification flow
│   │   ├── capture.tsx       # ID capture
│   │   ├── liveness.tsx      # Liveness challenge
│   │   └── review.tsx        # OCR review & submit
│   ├── conductor/            # Conductor flow
│   │   └── scanner.tsx       # QR Scanner
│   ├── route/                # Route planner flow
│   │   └── [results].tsx     # Fastest / Cheapest results
│   ├── ai/                   # AI Assistant flow
│   │   └── chat.tsx          
│   ├── _layout.tsx           # Root layout (Auth provider, toast provider)
│   └── +not-found.tsx        # 404 handler
├── src/
│   ├── components/           # Shared UI components (NativeWind)
│   │   ├── Button.tsx
│   │   ├── Card.tsx
│   │   ├── Input.tsx
│   │   ├── Toast.tsx
│   │   ├── Skeleton.tsx
│   │   └── map/              # Map specific components (Marker, Polyline)
│   ├── hooks/                # Custom React hooks (e.g., useAuth, useLocation)
│   ├── lib/                  # Configurations and third-party setup
│   │   ├── supabase.ts       # Supabase client initialization
│   │   └── gemini.ts         # Gemini API client
│   ├── services/             # Business logic and API calls
│   │   ├── routePlanner.ts   # Dijkstra algorithm implementation
│   │   ├── qrManager.ts      # Dynamic QR token generation
│   │   └── realtime.ts       # Supabase Realtime subscriptions
│   ├── store/                # Global state (if any, e.g., Zustand)
│   ├── theme/                # Global theme, colors (`#3b8132`), tokens
│   │   └── colors.ts
│   └── types/                # TypeScript interfaces and Supabase DB types
├── supabase/                 # Supabase configuration & migrations
│   ├── migrations/
│   ├── functions/            # Supabase Edge Functions
│   │   ├── vehicle-simulator/
│   │   └── qr-generator/
│   └── seed.sql
├── assets/                   # Images, fonts, splash screen, icons
├── app.json                  # Expo config (EAS setup, permissions)
├── tailwind.config.js        # NativeWind configuration
├── tsconfig.json
└── package.json
```

## 2. Dependencies

### Core
- `expo`
- `expo-router`
- `react-native`
- `react-native-safe-area-context`
- `react-native-screens`

### UI & Styling
- `nativewind` & `tailwindcss`
- `react-native-reanimated` (Animations)
- `moti` (Declarative animations)
- `@expo/vector-icons`

### Map & Location
- `react-native-maps`
- `expo-location`

### Backend & Data
- `@supabase/supabase-js`
- `react-native-url-polyfill` (required for Supabase in RN)
- `@react-native-async-storage/async-storage` (for local persistence)

### Camera & QR
- `expo-camera`
- `react-native-qrcode-svg`

### AI & Notifications
- `@google/generative-ai` (Gemini API for OCR & Chat)
- `expo-notifications`

## 3. Per-Feature Tasks

### Setup & Infrastructure
- [ ] Initialize Expo project with TypeScript and Expo Router.
- [ ] Install and configure NativeWind.
- [ ] Create Supabase project, execute SQL schema and RLS policies.
- [ ] Set up Supabase Edge Function for the vehicle simulator.
- [ ] Implement base UI components (Button, Input, Card, Skeleton, Toast) using the `#3b8132` theme.
- [ ] Setup authentication flow with Supabase Auth (Email/Password or Phone).

### Core Feature 1: Live Tracking & Route Planner
- [ ] Implement the `Home` screen with `react-native-maps`.
- [ ] Fetch stops/routes from Supabase and display on map.
- [ ] Set up Supabase Realtime subscription on the `vehicles` table.
- [ ] Add Moti for smooth interpolation of vehicle marker movements.
- [ ] Implement Route Planner (Dijkstra's) algorithm in `src/services/routePlanner.ts`.
- [ ] Build the Route Results UI (Fastest vs. Cheapest tabs).

### Core Feature 2: Digital Wallet & Dynamic QR Ticket
- [ ] Build the `Wallet` screen (Balance, mock top-up with RAAST/JazzCash, transaction list).
- [ ] Implement `My QR Pass` screen. Fetch or generate a dynamic rotating token (valid for 30s) bound to user.
- [ ] Build the `Conductor Scanner` screen using `expo-camera`.
- [ ] Implement logic to validate QR, deduct fare, and record a transaction in Supabase.

### Core Feature 3: Student Verification
- [ ] Build `Student Verification` flow: ID capture screen using `expo-camera`.
- [ ] Integrate Gemini API (Vision) to extract OCR data (name, institute, ID, expiry).
- [ ] Implement Liveness challenge (random prompt: blink/turn head) + selfie capture.
- [ ] Upload images to Supabase Storage and create a `student_verifications` record.
- [ ] Auto-approve simulation to update profile role to `student` and issue zero-fare QR.

## 4. Supabase SQL Schema & RLS

```sql
-- 1. Profiles (Extends auth.users)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  name TEXT,
  phone TEXT,
  role TEXT DEFAULT 'citizen', -- citizen, student, conductor
  student_verified BOOLEAN DEFAULT false,
  device_id TEXT
);

-- 2. Wallets
CREATE TABLE wallets (
  user_id UUID REFERENCES profiles(id) PRIMARY KEY,
  balance DECIMAL DEFAULT 0.00
);

-- 3. Transactions
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id),
  type TEXT, -- topup, deduction
  amount DECIMAL,
  method TEXT, -- raast, jazzcash, qr_scan
  status TEXT DEFAULT 'completed',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);

-- 4. Routes
CREATE TABLE routes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  network TEXT, -- speedo, metro, orange
  name TEXT
);

-- 5. Stops
CREATE TABLE stops (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  route_id UUID REFERENCES routes(id),
  name TEXT,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  seq INTEGER
);

-- 6. Fares
CREATE TABLE fares (
  network TEXT PRIMARY KEY,
  base_fare DECIMAL,
  per_stop DECIMAL
);

-- 7. Vehicles (Live Data)
CREATE TABLE vehicles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  route_id UUID REFERENCES routes(id),
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  heading DOUBLE PRECISION,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);

-- 8. Tickets (Dynamic QR)
CREATE TABLE tickets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id),
  qr_token TEXT UNIQUE,
  expires_at TIMESTAMP WITH TIME ZONE,
  is_student BOOLEAN DEFAULT false,
  used BOOLEAN DEFAULT false
);

-- 9. Student Verifications
CREATE TABLE student_verifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id),
  card_url TEXT,
  selfie_url TEXT,
  ocr_json JSONB,
  status TEXT DEFAULT 'pending' -- pending, approved, rejected
);

-- Enable Realtime for Vehicles
ALTER PUBLICATION supabase_realtime ADD TABLE vehicles;

-- Row Level Security (RLS) Examples
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own wallet" ON wallets FOR SELECT USING (auth.uid() = user_id);

ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own tickets" ON tickets FOR SELECT USING (auth.uid() = user_id);

-- (Additional granular policies needed for Conductors and Edge Functions)
```

## 5. API Contracts & Edge Functions

### 1. Vehicle Simulator (Supabase Edge Function / CRON script)
- **Trigger**: Every 1-2 seconds (via script or fast cron).
- **Action**: Read current vehicle positions, move them along their `route_id` polyline, update `lat`, `lng`, `heading`, and `updated_at`.
- **Output**: Writes to `vehicles` table (triggers Realtime).

### 2. Dynamic QR Token Generator (App -> DB)
- **Client Action**: App requests a new ticket when on `My QR Pass` screen.
- **Contract**: Generates a JWT or signed string containing `{ user_id, timestamp, is_student }`, valid for 30s.
- **Storage**: Upserts to `tickets` table with `expires_at = now() + 30s`.

### 3. QR Validation & Fare Deduction (Conductor Scanner)
- **Input**: QR Token string.
- **Action**:
  1. Verify token exists in `tickets` and `expires_at > now()`.
  2. If `is_student == true`, mark used, return success (Zero-fare).
  3. If normal user, check `wallets` balance > `base_fare`.
  4. Deduct balance, insert `transactions` record, mark ticket `used`.
- **Output**: `{ success: boolean, message: string, newBalance?: number }`

### 4. Gemini OCR Integration (App -> Gemini API)
- **Input**: Base64 image of Student Card.
- **Prompt**: "Extract student details from this card. Return JSON with keys: name, institute, student_id, expiry_date."
- **Output**: JSON payload used to populate `ocr_json` in `student_verifications`.

## 6. Component List

### Shared UI (Theme: `#3b8132`)
- **PrimaryButton**: Large, full-width, `#3b8132` background, white text.
- **OutlineButton**: Border `#3b8132`, clear background.
- **Card**: White background, slight shadow, rounded corners (for stops, wallet balance).
- **ToastNotification**: Slide-in from top (Success/Error states).
- **SkeletonLoader**: Moti-animated shimmering box for data fetching states.

### Feature Components
- **MapScreen**: Fullscreen `MapView`.
- **LiveMarker**: `Marker.Animated` with custom bus icon.
- **BottomSheet**: Interactive panel over the map for search and route results.
- **RouteCard**: Displays route summary (Time, Cost, Network icon).
- **TransactionItem**: Row with icon, title, date, and amount (green for top-up, red for deduction).
- **QRDisplay**: Contains `react-native-qrcode-svg`, countdown timer, and refresh animation.
- **CameraOverlay**: Framed overlay for ID capture with alignment guides.
