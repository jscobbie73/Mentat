# Mentat Implementation Plan

## Current State Assessment

The scaffolding is in place. The end-to-end paths that *actually work* today are:
1. Register/Login (email+password only)
2. Create a fragment (local SwiftData + backend with embedding generation)
3. Semantic search (backend pgvector query)
4. Safari capture and Share extension capture (both call backend)

Everything else is either stub UI ("will appear here"), defined-but-not-wired (Insights, Collections), or missing backend endpoints entirely.

---

## Implementation Order

### Phase 1: Backend — Complete the API (backend only)

**Why first:** Every client (Mac, iOS, Safari, Share) depends on the API. Building UI against missing endpoints wastes time. We complete the backend so all clients can consume it.

**1a. Collections CRUD** (`backend/src/routes/collections.ts`, `backend/src/models/collection.ts`, `backend/src/services/collections.ts`)
- POST `/api/collections` — create collection
- GET `/api/collections` — list user's collections
- GET `/api/collections/:id` — get collection with its fragments
- PATCH `/api/collections/:id` — rename/update
- DELETE `/api/collections/:id` — delete
- POST `/api/collections/:id/fragments` — add fragment to collection
- DELETE `/api/collections/:id/fragments/:fragmentId` — remove fragment
- Add Zod schemas: `CreateCollectionSchema`, `UpdateCollectionSchema`

**1b. Insights endpoints** (`backend/src/routes/insights.ts`, `backend/src/services/insights.ts`)
- GET `/api/insights` — list user's insights (paginated)
- GET `/api/fragments/:id/insights` — insights for a specific fragment
- POST `/api/fragments/:id/insights/generate` — trigger AI insight generation
- Implement `generateInsights()` service: calls OpenAI to produce summaries, themes, and "further reading" suggestions, stores them in the `insights` table
- Hook into fragment creation: auto-generate a summary insight when a fragment is created

**1c. Connection details** (`backend/src/routes/fragments.ts` update)
- GET `/api/fragments/:id/connections` currently returns similar fragments — enhance to also return the stored `ai_summary` from the `connections` table
- Add stored connection lookup (not just live similarity search)

**1d. Apple Sign In endpoint** (`backend/src/routes/auth.ts`)
- POST `/api/auth/apple` — verify Apple identity token, create or find user, return JWT
- Use the already-defined `AppleSignInSchema`

**1e. Rate limiting and async error handling**
- Add express-rate-limit middleware on auth routes (prevent brute force)
- Wrap all route handlers in async error catcher so unhandled rejections return 500 properly instead of crashing

**Reasoning:** Doing all backend work as a single phase means we can test endpoints with curl/Postman before touching any Swift code. No back-and-forth.

---

### Phase 2: Shared Swift Layer — Wire Up New Endpoints

**Why second:** The shared networking layer is used by Mac, iOS, Safari extension, and Share extension. Fixing it once propagates everywhere.

**2a. APIClient additions** (`apple/Shared/Networking/APIClient.swift`)
- Add PATCH and DELETE HTTP methods to the generic helpers
- Add collection methods: create, list, get, update, delete, addFragment, removeFragment
- Add insight methods: listForFragment, generate
- Add Apple Sign In method
- Make baseURL configurable (dev vs production) via a build configuration

**2b. APIModels additions** (`apple/Shared/Networking/APIModels.swift`)
- Add request/response models for collections and insights
- Add AppleSignInRequest/Response
- Fix metadata type: `[String: String]` → use a proper `AnyCodable` or `[String: AnyCodableValue]` wrapper to match backend's `Record<string, unknown>`

**2c. FragmentStore enhancements** (`apple/Shared/Services/FragmentStore.swift`)
- Add collection operations (create, list, add/remove fragments)
- Add sync triggers: pull-to-refresh, app-foreground sync
- Add error state that UI can observe (`@Observable` property)

**2d. AuthManager — Apple Sign In** (`apple/Shared/Services/AuthManager.swift`)
- Implement `signInWithApple()` using `ASAuthorizationAppleIDProvider`
- Handle credential response, send identityToken to backend
- Store in Keychain just like password login

**2e. CollectionStore** (`apple/Shared/Services/CollectionStore.swift` — new file)
- @Observable store mirroring FragmentStore's pattern
- Local SwiftData persistence + remote sync

**Reasoning:** This is the shared code layer. Every UI change in phases 3-6 calls into these services. Complete them once, all platforms benefit.

---

### Phase 3: Core UI — Fragment Detail (Connections + Insights)

**Why third:** This is the highest-value feature for a "second brain." Users create fragments, then the magic is seeing how they connect. The backend is ready from Phase 1, the networking from Phase 2.

**3a. Mac fragment detail** (`apple/MentatMac/Sources/ContentView.swift`)
- Replace placeholder text in `FragmentDetailView` with actual async-loaded connections and suggestions
- Show connection cards with similarity scores and AI summaries
- Show suggestion chips that are tappable (could create a search or open Safari)

**3b. iPhone fragment detail** (`apple/MentatiOS/Sources/MobileContentView.swift`)
- Replace `MobileFragmentDetailView` placeholder sections with real data
- Add `task {}` modifier to load connections and suggestions on appear
- Connection cards: show title, similarity badge, AI summary
- Suggestion list: tappable items

**3c. iPad fragment detail** (`apple/MentatiOS/Sources/iPadFragmentDetailView.swift`)
- Already has loading states and structure — wire it up properly
- Ensure connection cards display the `aiSummary` field (currently only shows title/content)
- Make connection cards tappable to navigate to the connected fragment

**Reasoning:** This is the core differentiator of the app. Fragment capture already works. Making the AI-powered connections *visible* is what makes Mentat a second brain instead of just a notes app.

---

### Phase 4: Collections Feature End-to-End

**Why fourth:** Collections are organizational — important, but secondary to capture and connections. Users need a critical mass of fragments before collections matter.

**4a. CollectionsView — Mac** (`apple/MentatMac/Sources/` — new views)
- Sidebar section showing collections
- Create/rename/delete collections
- Drag fragments into collections

**4b. CollectionsView — iPhone** (`apple/MentatiOS/Sources/MobileContentView.swift`)
- Replace the placeholder `CollectionsView` with a real list
- Create collection sheet
- Collection detail: shows fragments in that collection
- Swipe-to-remove fragment from collection

**4c. CollectionsView — iPad** (`apple/MentatiOS/Sources/iPadContentView.swift`)
- Replace `iPadCollectionsList` placeholder
- Collection list in the content column, fragments in detail
- Drag-and-drop fragments between collections

**4d. Add-to-collection from fragment detail** (all platforms)
- The "Add to Collection" button in detail views currently does nothing — wire it up
- Present a picker of existing collections or create-new option

**Reasoning:** Backend is done (Phase 1), networking is done (Phase 2), now it's pure UI work on each platform.

---

### Phase 5: Discover Tab — AI Insights Hub

**Why fifth:** The Discover tab is currently an empty placeholder. With Phases 1-3 done, we have connections and insights stored in the database. This phase surfaces them.

**5a. Discover — iPhone** (`apple/MentatiOS/Sources/MobileContentView.swift`)
- Replace placeholder `DiscoverView`
- Show recent AI connections between fragments (grouped by theme)
- Show insights: summaries, suggested reading, themes across all fragments
- "Daily brief" concept: a summary of your recent captures and what connects them

**5b. Discover — iPad** (`apple/MentatiOS/Sources/iPadContentView.swift`)
- Replace `iPadDiscoverList` with a rich grid layout
- Connection graph visualization (simplified: cards with lines between them)
- Insights carousel

**5c. Discover — Mac** (`apple/MentatMac/Sources/` — new view)
- Similar to iPad: wider layout with connection cards and insight panels
- Possibly a visual "web" of connected fragments

**Reasoning:** Discover is the showcase feature but depends on all prior phases: backend insights, networking, and a populated fragment store.

---

### Phase 6: Sync & Offline

**Why sixth:** The infrastructure exists (FragmentStore.sync()) but is never called. This phase makes it real.

**6a. Auto-sync triggers**
- Sync on app foreground (ScenePhase → .active)
- Sync after creating a fragment (already partially done)
- Periodic background sync via BGAppRefreshTask (iOS)

**6b. Pull-to-refresh** (all list views)
- Add `.refreshable {}` modifier to fragment lists
- Call `store.sync()` on pull

**6c. Sync status indicator**
- Show sync state in the UI (syncing spinner, last synced timestamp, error badge)
- Surface network errors gracefully

**6d. Conflict resolution**
- Server-wins strategy for v1 (simplest — server timestamp is authoritative)
- Track local-only fragments that haven't synced yet (show an "unsynced" indicator)

**Reasoning:** Offline support is important for a mobile app but it's a cross-cutting concern. Better to get the feature set right first, then layer on resilience.

---

### Phase 7: Authentication Polish

**7a. Sign in with Apple UI** (all Apple platforms)
- Add `SignInWithAppleButton` to the login/settings views
- Wire to AuthManager.signInWithApple() (Phase 2d)

**7b. Login/Register screens**
- Currently there are no actual login screens — the app assumes you're authenticated
- Create a proper auth gate: if not authenticated, show login/register
- Email + password form
- Sign in with Apple button

**7c. Token refresh**
- Detect 401 responses in APIClient, clear Keychain, redirect to login
- Consider refresh tokens for v2

**Reasoning:** Auth works mechanically but there's no UI flow. This blocks real-world use but not development, so it's later.

---

### Phase 8: Mac-Specific Features

**8a. Menu bar quick capture** (`apple/MentatMac/Sources/ContentView.swift`)
- "New Note..." opens a floating capture window
- "Paste from Clipboard" reads pasteboard, creates fragment immediately
- Global hotkey for capture (Cmd+Shift+M)

**8b. URL scheme handling**
- Register `mentat://` URL scheme
- Handle `mentat://capture?text=...&url=...` for automation/Shortcuts integration

**8c. Keyboard shortcuts throughout Mac app**
- Cmd+F for search focus
- Cmd+Delete for delete
- Arrow keys for fragment navigation

**Reasoning:** Mac-specific features are polish on top of the core feature set. Important for a good Mac app but not blocking.

---

### Phase 9: Testing & Hardening

**9a. Backend tests** (vitest)
- Unit tests for AI service (mock OpenAI)
- Integration tests for auth routes
- Integration tests for fragment CRUD
- Integration tests for collection CRUD

**9b. Swift tests**
- Unit tests for APIClient (mock URLSession)
- Unit tests for FragmentStore (mock API, in-memory SwiftData)
- UI tests for core flows (create fragment, view connections)

**9c. Error handling audit**
- Backend: ensure every route handler catches async errors
- iOS/Mac: surface errors to user with alerts
- Safari extension: show error state in popup

**Reasoning:** Tests come last not because they're unimportant, but because the API contracts are still being established in earlier phases. Testing against stable interfaces is more productive.

---

## Summary

| Phase | Scope | Key Deliverable |
|-------|-------|----------------|
| 1 | Backend only | Complete API: collections, insights, Apple auth, connections |
| 2 | Shared Swift | Complete networking + data layer for all Apple clients |
| 3 | UI (all platforms) | Fragment detail shows real AI connections and suggestions |
| 4 | UI (all platforms) | Collections feature works end-to-end |
| 5 | UI (all platforms) | Discover tab surfaces AI insights and connection themes |
| 6 | Infrastructure | Sync, offline, pull-to-refresh, conflict resolution |
| 7 | UI (all platforms) | Login screens, Sign in with Apple, auth gating |
| 8 | Mac only | Menu bar capture, URL schemes, keyboard shortcuts |
| 9 | All | Backend + Swift tests, error handling audit |
