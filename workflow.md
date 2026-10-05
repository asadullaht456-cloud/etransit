# Lahore Unified Transit App: Workflow

## 1. Project Goal
Android app unifying Speedo, Metrobus, and Orange Line: live fleet tracking, multi-modal route planning, digital wallet and QR ticketing, and automated zero-fare student verification.

**Theme:** primary `#3b8132` (green), high-contrast, high-glare friendly.
**Build time:** 4 hours. **Deliverables:** installable APK, demo video (1-2 min), live APK demo.

---

## 2. Tech Stack

| Layer | Choice |
|---|---|
| App | React Native + Expo (TypeScript), Expo Router |
| UI design | Google Stitch (screens) + NativeWind (Tailwind styling) |
| Animations | React Native Reanimated + Moti |
| Map | react-native-maps (Google Maps) |
| Backend / DB / Auth | Supabase (Postgres, Auth, Realtime, Storage) |
| QR | react-native-qrcode-svg, expo-camera (scanner) |
| Camera / Location / Notifications | expo-camera, expo-location, expo-notifications |
| OCR + AI | Gemini API (vision for student card OCR, AI route assistant) |
| Build | EAS Build (APK) |
| Dev testing | Expo Go (until native modules are needed) |

**Constraint:** Expo Go cannot run NFC or custom native modules. NFC is simulated. Final APK is built via EAS.

---

## 3. Scope

### Core features (must work end to end)
1. **Live Tracking + Route Planner**
   - Map with simulated buses for the 3 networks, position updates via Supabase Realtime (target under 3 s latency)
   - Route planner: origin, destination, toggle "Fastest" or "Cheapest", multi-modal result
2. **Digital Wallet + Dynamic QR Ticket**
   - Balance, top-up (RAAST / JazzCash as mock gateway), transaction history
   - Pay-as-you-go dynamic QR (rotating token, refreshes every 30 s)
   - Scanner screen (conductor mode) validates QR and deducts fare
3. **Student Privilege Verification**
   - Upload student card photo, Gemini OCR extracts name, institute, ID, expiry
   - Liveness check: camera with random challenge (blink / turn head) and selfie capture
   - Admin approval auto-simulated, account upgraded, zero-fare QR generated and bound to device ID

### Simulated / stretch
- NFC card binding: UI flow + mock binding (real NFC needs dev build)
- Real RAAST / JazzCash APIs: sandbox mock only

### Standout feature (Innovation, pick one)
- **AI Commute Assistant:** natural language ("Gulberg to Airport cheapest, student") returns route + fare; optional crowd prediction per bus

---

## 4. Screens (design in Stitch)
1. Splash / Onboarding
2. Login / Sign up (Supabase Auth, email or phone)
3. Home (map with live buses, search bar, bottom sheet)
4. Route Results (fastest / cheapest tabs)
5. Wallet (balance, top-up, history)
6. Top-up (RAAST / JazzCash options)
7. My QR Pass (dynamic QR, timer)
8. Student Verification (card upload, OCR review, liveness, status)
9. Conductor Scanner
10. Profile / Settings
11. AI Assistant chat

**UI rules:** `#3b8132` primary, white/dark surfaces, large text, high contrast; loading skeletons, empty states, error toasts, success feedback on every action; no dead buttons.

---

## 5. Data Model (Supabase)

- `profiles` (id, name, phone, role: citizen/student/conductor, student_verified, device_id)
- `wallets` (user_id, balance)
- `transactions` (id, user_id, type, amount, method, status, created_at)
- `routes` (id, network: speedo/metro/orange, name)
- `stops` (id, route_id, name, lat, lng, seq)
- `fares` (network, base_fare, per_stop)
- `vehicles` (id, route_id, lat, lng, heading, updated_at)
- `tickets` (id, user_id, qr_token, expires_at, is_student, used)
- `student_verifications` (id, user_id, card_url, selfie_url, ocr_json, status)

Row Level Security enabled on all user tables.

---

## 6. Workflow (4-hour timeline)

### Phase 0: Setup (0:00 - 0:20)
- Init Expo TypeScript project, install dependencies, Expo Router, NativeWind
- Create Supabase project, tables, RLS, seed routes / stops / fares
- Push base to GitHub, share repo

### Phase 1: Design + Base (0:20 - 0:50)
- Generate screens in Stitch, export theme tokens
- Build theme file, shared components (Button, Card, Input, Toast, Skeleton)
- Navigation (tabs: Home, Wallet, Pass, Profile) + auth flow

### Phase 2: Core Feature 1, Tracking + Routing (0:50 - 1:50)
- Map screen with stops and route polylines
- Vehicle simulator script (Supabase Edge Function or Node script) updating `vehicles` every 1-2 s
- Realtime subscription, animated markers
- Route planner logic: graph of stops, Dijkstra on time or fare, interchange handling

### Phase 3: Core Feature 2, Wallet + QR (1:50 - 2:40)
- Wallet screen, mock top-up flow, transaction history
- Dynamic QR token generation (signed, 30 s expiry) via Edge Function
- Conductor scanner validates token, deducts fare, writes transaction

### Phase 4: Core Feature 3, Student Verification (2:40 - 3:20)
- Card capture, Gemini OCR extraction, review screen
- Liveness challenge + selfie, store in Supabase Storage
- Status update, student flag, zero-fare QR bound to `device_id`

### Phase 5: Innovation + Polish (3:20 - 3:40)
- AI Commute Assistant (Gemini)
- Push notifications (bus arriving, top-up success)
- Animations, empty / loading / error states

### Phase 6: Build + Demo (3:40 - 4:00)
- EAS build APK, install and test on a real device
- Record 1-2 min demo video
- Prepare pitch

---

## 7. Demo Flow (1-2 min)
1. Open app, live buses moving on map
2. Plan route Fastest vs Cheapest
3. Top up wallet, show dynamic QR, scan with conductor mode
4. Student verification, zero-fare QR
5. AI assistant query

---

## 8. Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Real fleet GPS unavailable | Simulated vehicles with realistic paths |
| Realtime latency over 3 s | Supabase Realtime + marker interpolation |
| NFC not in Expo Go | Mock NFC binding; mention as roadmap |
| RAAST / JazzCash integration | Sandbox mock gateway |
| 3D liveness complexity | Randomized challenge + capture, AI-assisted check |
| Build failure at the end | Run test EAS build by hour 2 |
| Scope creep | Freeze features at 3:20 |

---

## 9. Instruction for Antigravity
Create a detailed implementation plan from this workflow: folder structure, dependencies, per-feature tasks, API contracts, Supabase SQL schema, and component list. Prioritize the 3 core features working without crashes or dead buttons.
