# Shared Schema and Contract (SINGLE SOURCE OF TRUTH)

All agents MUST follow this file exactly. Do not rename tables, columns, types, routes, or env vars. If a change is needed, update this file first, then push.

---

## 1. Conventions
- Language: TypeScript everywhere
- Table and column names: `snake_case`
- TS types and components: `PascalCase`; variables and functions: `camelCase`
- IDs: `uuid` (except `stops`/`routes` seed IDs, which are `text`)
- Money: integer PKR (no decimals)
- Timestamps: `timestamptz`, UTC
- Network enum: `'speedo' | 'metro' | 'orange'`
- Theme primary: `#3b8132`

---

## 2. Folder Structure
*See `implementation_plan.md` for the official folder structure.*

---

## 3. Database Schema
*See `schema.sql` for the official Supabase schema and RLS policies.*

---

## 4. Shared Types (`lib/types.ts`)

```ts
export type Network = 'speedo' | 'metro' | 'orange';
export type Role = 'citizen' | 'student' | 'conductor';

export interface Profile {
  id: string;
  name: string;
  phone: string | null;
  role: Role;
  student_verified: boolean;
  device_id: string | null;
}

export interface Wallet { user_id: string; balance: number; }

export interface Transaction {
  id: string;
  user_id: string;
  type: 'topup' | 'fare' | 'refund';
  amount: number;
  method: string | null;
  status: 'pending' | 'success' | 'failed';
  ref: string | null;
  created_at: string;
}

export interface Route { id: string; network: Network; name: string; }

export interface Stop {
  id: string;
  route_id: string;
  name: string;
  lat: number;
  lng: number;
  seq: number;
}

export interface Fare { network: Network; base_fare: number; per_stop: number; }

export interface Vehicle {
  id: string;
  route_id: string;
  lat: number;
  lng: number;
  heading: number;
  speed: number;
  updated_at: string;
}

export interface Ticket {
  id: string;
  user_id: string;
  qr_token: string;
  is_student: boolean;
  device_id: string | null;
  expires_at: string;
  used: boolean;
}

export interface RouteLeg {
  network: Network;
  route_id: string;
  from_stop_id: string;
  to_stop_id: string;
  stops_count: number;
  duration_min: number;
  fare: number;
}

export interface RoutePlan {
  legs: RouteLeg[];
  total_duration_min: number;
  total_fare: number;
  mode: 'fastest' | 'cheapest';
}
```

---

## 5. Service Function Contracts (names fixed)

```ts
// vehicleService.ts
subscribeVehicles(cb: (v: Vehicle) => void): () => void
getRoutes(): Promise<Route[]>
getStops(): Promise<Stop[]>

// routing.ts
planRoute(fromStopId: string, toStopId: string, mode: 'fastest'|'cheapest', isStudent: boolean): RoutePlan

// walletService.ts
getWallet(): Promise<Wallet>
topUp(amount: number, method: 'raast'|'jazzcash'): Promise<Transaction>
getTransactions(): Promise<Transaction[]>

// ticketService.ts
generateTicket(): Promise<Ticket>             // refreshes every 30s
validateTicket(qrToken: string, fromStopId: string, toStopId: string): Promise<{ ok: boolean; fare: number; message: string }>

// studentService.ts
uploadStudentCard(uri: string): Promise<{ card_url: string; ocr: Record<string,string> }>
submitLiveness(selfieUri: string): Promise<{ passed: boolean }>
submitVerification(): Promise<{ status: 'pending'|'approved'|'rejected' }>

// aiService.ts
askAssistant(query: string): Promise<{ answer: string; plan?: RoutePlan }>
```

---

## 6. Business Rules (all agents must follow)
- Student verified: fare = 0, ticket `is_student = true`, bound to `profiles.device_id`
- Ticket QR payload: `{ "t": "<qr_token>" }`, expiry 30 s
- Fare formula: `base_fare + per_stop * stops_count` per leg
- Fare defaults (seed): speedo 30 + 0/stop, metro 30 + 0/stop, orange 40 + 0/stop
- Top-up min 100, max 10000 PKR
- Wallet balance can never go below 0; validate fare against balance before deduction
- Interchange penalty in routing: 5 min per transfer

---

## 7. Environment Variables (`.env`, same names for all)
```
EXPO_PUBLIC_SUPABASE_URL=
EXPO_PUBLIC_SUPABASE_ANON_KEY=
EXPO_PUBLIC_GEMINI_API_KEY=
EXPO_PUBLIC_GOOGLE_MAPS_API_KEY=
```

---

## 8. Git Rules
- Branches: `feat/tracking-routing`, `feat/wallet-qr`, `feat/student-verify`
- Commit small, pull from `main` every 30 min
- Never edit another teammate's service or screen files
- Shared file changes: tell the group, then push to `main` directly and everyone pulls
