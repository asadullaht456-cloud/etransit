# Agent Collaboration & Task Division Plan

To ensure all 3 Antigravity agents can work seamlessly together, the work is divided into a Lead/QA, Frontend, and Backend model. 

## 🤝 Task Division

### 👑 Agent 1: Lead, QA & Integrator
**Role:** Project Manager, Code Reviewer, and Integration Tester.
**Access:** Full access to review **and modify** Frontend and Backend code.
- **⚠️ Prompt Prefix Rule:** Agent 1 must start every prompt with one of the following:
  - `/frontend` — to review or modify Frontend code (`app/`, `src/components/`)
  - `/backend` — to review or modify Backend code (`supabase/`, `src/services/`)
- **Tasks:**
  1. Initialize the project base and manage the overarching architecture.
  2. Review code pushed by Frontend and Backend agents to ensure they connect properly.
  3. Test the app end-to-end (e.g., verifying that the frontend map successfully receives backend realtime updates).
  4. Fix build errors, dependency issues (like the `npx expo start` error), and merge conflicts.
  5. Ensure UI/UX matches the design guidelines and the backend follows the `schema.sql` rules.

### 🎨 Agent 2: Frontend Engineer (React Native + Expo)
**Role:** UI/UX, Screens, Animations, and Local State.
- **Tasks:**
  1. Build all the screens in Expo Router (`app/` directory) and apply NativeWind (`#3b8132` theme).
  2. Create reusable UI components (Buttons, Bottom Sheets, Cards, Skeleton loaders).
  3. Implement `react-native-maps`, polyline rendering, and Moti animations for vehicles.
  4. Build the QR scanner UI (using `expo-camera`) and the Student ID capture screens.
  5. Connect to the backend APIs provided by Agent 3 (using mocked data until the backend is ready).

### ⚙️ Agent 3: Backend Engineer (Supabase + APIs)
**Role:** Database, Edge Functions, Auth, and AI Services.
- **Tasks:**
  1. Manage the `schema.sql` (Tables, Row Level Security policies, Seed data).
  2. Write Supabase Edge Functions (e.g., the Vehicle Simulator script, Dynamic QR Generator).
  3. Implement the `routePlanner.ts` (Dijkstra algorithm) and ensure fast pathfinding.
  4. Integrate the Gemini Vision API for Student ID OCR extraction and AI Commute Chatbot logic.
  5. Set up Supabase Realtime for live bus tracking and Wallet transaction processing.

---

## 🛠️ Rules for Collaboration
1. **🚀 Onboarding — State Your Dev Number First:** When a collaborator starts working on the project, they **must** declare their agent/dev number (1, 2, or 3) before doing anything else. They will then work **strictly according to the role and tasks** assigned to that number above.
   - Example: *"I am Dev 2"* → works as the Frontend Engineer.
   - Example: *"I am Dev 3"* → works as the Backend Engineer.
   - Example: *"I am Dev 1"* → works as Lead/QA (must use `/frontend` or `/backend` prefix on every prompt).
2. **Clear Boundaries:** Frontend (Agent 2) handles anything in `app/` and `src/components/`. Backend (Agent 3) handles anything in `supabase/` and `src/services/`.
3. **API Contracts:** Agent 3 must define the exact input/output of functions (e.g., QR deduction) so Agent 2 can build the UI without waiting.
4. **Lead Check:** Agent 1 will regularly test the integration points between Agent 2 and Agent 3 to ensure everything runs smoothly.
