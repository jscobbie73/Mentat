# GenRx — App Specification
**Version:** 0.1 (Pre-Development Draft)
**Platform:** iOS 17+
**Framework:** SwiftUI + SwiftData
**Target Audience:** Gen X (born ~1965–1980, ages 46–61 in 2026)

---

## 1. Concept

GenRx is a medication and injection reminder app built specifically for Gen X — the generation that grew up without helicopter parents, survived the 80s, and is now reluctantly managing a small pharmacy's worth of daily prescriptions. The app respects their intelligence, shares their dark humor, and doesn't treat them like children.

**Tagline options:**
- *"Your pills. Your schedule. Whatever."*
- *"Medication management for people who lived through the 80s and somehow need pills because of it."*
- *"Finally, an app that gets it."*

---

## 2. Target Audience Deep Dive

**Demographics:** 46–61 year olds, iPhone-centric, digitally literate but not digital natives, high disposable income, no patience for patronizing UX.

**Pain points this app solves:**
- Managing multiple medications with different schedules (daily, weekly, every N days)
- Tracking injections that require site rotation (GLP-1s, testosterone, biologics)
- Actually remembering if you took something or just *thought* you did
- Health apps that feel like they were designed for Boomers or teenagers

**What they don't want:**
- Pastel colors and bubbly fonts
- Notification copy that reads like a nurse talking to a 5-year-old
- Gamification, streaks, rewards, badges, or any of that nonsense
- An app that asks too many questions or requires too many taps

**What they do want:**
- Fast, no-friction daily use
- Something that feels like it has a personality
- Respect for their autonomy (no nagging tone, just dry acknowledgment)
- Solid functionality without bloat

---

## 3. Core Feature Set (MVP)

### 3.1 Medication Management
- Add, edit, and archive medications
- Support for multiple medication types:
  - **Pill/Capsule** — standard oral meds
  - **Injection** — includes site rotation tracking
  - **Topical** — gels, patches, creams
  - **Other** — catch-all
- Fields per medication:
  - Name
  - Type (pill/injection/topical/other)
  - Dosage (free text, e.g., "10mg", "0.5mL")
  - Schedule (see 3.2)
  - Time(s) of day
  - Injection site rotation list (if injection type)
  - Color tag (for visual scanning)
  - Notes (free text)

### 3.2 Scheduling System
Four frequency modes:
1. **Daily** — one or more times per day, every day
2. **Weekly** — specific day(s) of the week
3. **Every N Days** — e.g., every 7 days, every 14 days (for bi-weekly injections)
4. **As Needed (PRN)** — no automatic reminder; log-only

### 3.3 Today View (Home Screen)
- Chronological list of today's scheduled doses
- Each dose card shows:
  - Medication name + type icon
  - Scheduled time
  - Dosage
  - For injections: current rotation site
  - Status: Pending / Taken / Skipped / Missed
- One-tap "Mark Taken" action
- Swipe actions: Take / Skip
- Past-due doses automatically flagged as Missed at end of day
- Quick summary header: "X of Y done. Keep going."

### 3.4 Dose Logging
- Mark taken (with timestamp)
- Mark skipped (with optional reason)
- Log an off-schedule/as-needed dose
- For injections: confirm or change the rotation site at time of logging
- Edit a log entry (within 24 hours)

### 3.5 Injection Site Rotation
- User defines rotation list per injection medication (e.g., Left Belly, Right Belly, Left Thigh, Right Thigh, Left Arm, Right Arm)
- App tracks current position in rotation
- Rotation advances automatically when dose is logged as taken
- Visual rotation display showing current site highlighted
- History shows which site was used for each injection

### 3.6 History & Tracking
- Calendar or list view of past doses
- Filter by medication
- Adherence stats:
  - Overall % taken on time
  - Per-medication breakdown
  - 7-day and 30-day views
- Missed dose log
- Export (CSV) for sharing with doctor

### 3.7 Notifications
- **Type:** Local notifications only (no server required, works offline)
- **Scheduling:** Up to ~60 pending notifications per medication cycle
- **Reminders per dose:** Primary reminder at scheduled time + optional follow-up (configurable: 15/30/60 min later if not marked)
- **Copy style:** Gen X snarky (see Section 6)
- **Notification actions:** Mark Taken / Snooze directly from notification banner
- **Do Not Disturb:** Respect system DND; no override

### 3.8 HealthKit Integration
- **Authorization:** Request read/write at first launch (with clear explanation)
- **Phase 1 (MVP):** Foundation only — request permissions, display connection status
- **Phase 2:** Write medication dose events to HealthKit when logged
- **Phase 3:** Read relevant health context (weight, heart rate, blood pressure) to surface alongside medication history
- **Legal posture:** App is not a medical device. Does not provide medical advice. Standard App Store disclaimer.

---

## 4. Theme System

Three selectable visual themes accessible from Settings. Theme persists via `@AppStorage`. All themes support both dark and light mode *except* where the theme is inherently one mode (Synthwave = always dark, Memphis = always light, VHS = always dark).

### 4.1 Synthwave (Default)
**Vibe:** Tron, Blade Runner, late-night drive down a neon-lit highway  
**Color palette:**
- Background: Deep purple-black `#0A0014`
- Surface: Dark purple `#12001F`
- Primary: Hot pink `#FF2D78`
- Secondary: Electric cyan `#00F5FF`
- Accent: Purple `#BF5FFF`
- Success: Neon green `#00FF9F`
- Warning: Yellow `#FFD600`
- Text: White / off-white

**Visual treatments:**
- Horizontal grid lines in background (subtle, 1px, 5–10% opacity)
- Glow/bloom effect on primary UI elements (box shadow + blur)
- Thin neon borders on cards
- Typography: Heavy geometric sans (SF Pro Display Heavy or custom)

**Tagline:** *"Tron called. It wants its pills back."*

### 4.2 Memphis
**Vibe:** Saved by the Bell, 1987 trapper keeper, every furniture ad from 1986  
**Color palette:**
- Background: Off-white `#FAFAFA`
- Surface: White `#FFFFFF`
- Primary: Red `#E63946`
- Secondary: Blue `#2196F3`
- Accent: Orange `#FF9800`
- Text: Near-black `#1A1A1A`

**Visual treatments:**
- Geometric shapes (zigzags, dots, triangles) scattered in backgrounds — rendered in SwiftUI, not images
- Bold, thick borders on cards (2–3px)
- Sharp corners (minimal border radius)
- Typography: System rounded, heavy weight
- Deliberate pattern chaos (no grid alignment on decorative elements)

**Tagline:** *"Geometric. Chaotic. Medicated."*

### 4.3 VHS
**Vibe:** Saturday night Blockbuster run, rewinding tapes, green text on black CRT  
**Color palette:**
- Background: Near-black `#0D0D0D`
- Surface: `#161616`
- Primary: Phosphor green `#00FF41`
- Secondary: VCR orange `#FF6B35`
- Accent: Yellow `#FFFF00`
- Text: Light gray `#E8E8E8`

**Visual treatments:**
- Horizontal scanlines overlay (CSS/Canvas-style thin lines, ~15% opacity)
- Grain/noise texture on surfaces
- Monospaced typography throughout
- Occasional "tracking" glitch effect on header text (subtle animated offset)
- UI chrome styled like a VCR display (time display in mono font)

**Tagline:** *"Be kind, rewind, and take your meds."*

---

## 5. Information Architecture

```
Tab Bar
├── Home (Today)
│   └── Dose cards → Tap to log / swipe to take/skip
├── Medications
│   ├── Medication list
│   │   └── Medication detail
│   │       ├── Edit medication
│   │       └── Injection site rotation view
│   └── Add medication (+ button)
├── History
│   ├── Calendar view
│   ├── List view
│   └── Stats/adherence view
└── Settings
    ├── Theme picker
    ├── Notification preferences
    │   ├── Global on/off
    │   └── Follow-up reminder delay
    ├── HealthKit
    │   └── Connection status + permissions
    └── About / Credits
```

---

## 6. Voice & Copy Guidelines

### Tone Principles
- **Dry, not mean.** The app is sarcastic about aging, not about the user's health.
- **Self-aware.** The app knows it's a pill reminder. It owns that.
- **Brief.** Gen X doesn't read paragraphs in apps.
- **No exclamation points.** Ever. Hard rule.
- **No "Amazing!", "Great job!", or any positive reinforcement language.** They're not children.
- **OK to be dark, not OK to be nihilistic.** There's a difference.

### Sample Notification Copy (by medication type)

**Generic reminders:**
- "Time for [MedName]. Your future self is watching."
- "[MedName]. You know the drill."
- "Still ignoring [MedName]? Bold strategy."
- "The [MedName] isn't going to take itself. Unfortunately."
- "[MedName] o'clock. Don't make it weird."
- "Unread: 1 medication. From: Your Body."

**Injection-specific:**
- "Injection time. [Site] is up. Get a needle."
- "[MedName] injection. [Site]. You've done harder things."
- "Jab day. [Site]. Don't think about it, just do it."

**Follow-up / missed:**
- "Still waiting on that [MedName]."
- "[MedName] is giving you a look right now."
- "One hour ago: [MedName]. Still waiting."

**Morning greeting (first dose of day):**
- "Rise and medicate."
- "Another day in the timeline. Let's get you chemically balanced."
- "Morning. Your [MedName] has been waiting since [time]."
- "Coffee can wait. [MedName] cannot. (Coffee cannot actually wait.)"

### Sample UI Microcopy

| Context | Copy |
|---|---|
| Empty today screen | "Nothing due right now. Enjoy it." |
| All doses taken | "All done. See you tomorrow." |
| App first launch | "You found GenRx. Good. Let's set up your meds and get out of each other's way." |
| Onboarding step 1 | "Add your medications below. There's no judgment here." |
| Delete confirmation | "Delete [MedName]? You won't be reminded anymore. Obviously." |
| Notification permission | "We need permission to bother you at scheduled times. That's literally the whole app." |
| HealthKit permission | "Optional: sync your dose logs to Apple Health. Useful if your doctor wants data. No weird tracking." |
| History empty state | "No history yet. Check back after you've actually taken something." |
| Streak display | Removed entirely. No streaks. |

---

## 7. Data Models

### Medication
```
id: UUID
name: String
type: MedicationType (pill | injection | topical | other)
dosage: String
frequency: FrequencyType (daily | weekly | everyNDays | asNeeded)
timesOfDay: [String]        // ["08:00", "20:00"] — 24hr format
daysOfWeek: [Int]           // [2, 4] = Tuesday/Thursday, 1=Sunday
intervalDays: Int           // for everyNDays: e.g., 7 or 14
startDate: Date
injectionSites: [String]    // ["Left Belly", "Right Belly", ...]
currentSiteIndex: Int
colorHex: String            // for UI color coding
notes: String
isActive: Bool
createdAt: Date
```

### DoseLog
```
id: UUID
medicationID: UUID
medicationName: String      // denormalized for history reads
medicationType: MedicationType
scheduledTime: Date
takenTime: Date?
status: DoseStatus (pending | taken | skipped | missed)
injectionSite: String?      // site used, if injection
notes: String
```

---

## 8. Technical Architecture

**Language:** Swift 5.9+  
**Framework:** SwiftUI  
**Persistence:** SwiftData (iOS 17+)  
**Notifications:** UserNotifications framework (local only)  
**Health:** HealthKit framework  
**Min iOS:** 17.0  
**Orientation:** Portrait only  
**Device:** iPhone only (iPad not targeted in v1)

### Key Technical Decisions

| Decision | Choice | Rationale |
|---|---|---|
| State management | `@Observable` + SwiftData | Modern iOS 17 pattern, no boilerplate |
| Persistence | SwiftData | Replaces Core Data, simpler schema definition |
| Notifications | Local only | No backend cost, works offline, sufficient for solo use |
| Theme distribution | `@Environment` injection | Clean, composable, no singleton abuse |
| Navigation | `NavigationStack` | iOS 16+ native, programmatic navigation |
| Health logging | HealthKit (Phase 2) | Requires more API research; placeholder in MVP |

---

## 9. Notification Scheduling Logic

- Daily meds: `UNCalendarNotificationTrigger` with `.hour` and `.minute`, `repeats: true`
- Weekly meds: `UNCalendarNotificationTrigger` with `.weekday`, `.hour`, `.minute`, `repeats: true`
- Every N days: Compute next 8 occurrences from today, schedule individually; reschedule on app foreground
- App stores max ~60 pending notifications across all medications (system limit is 64)
- On app foreground: audit pending notifications, reschedule any that have been consumed

---

## 10. Future Features (Post-MVP)

| Feature | Notes |
|---|---|
| Caregiver mode | Family sharing via iCloud / CloudKit; spouse/adult child gets notifications for missed doses |
| Push notifications | Would require a lightweight backend (Firebase, etc.); enables caregiver mode |
| HealthKit full write | Log dose events to Apple Health once API approach is confirmed |
| Doctor visit prep | One-tap adherence summary report for medical appointments |
| Drug interaction warnings | Integration with a drug database API (significant regulatory/legal consideration) |
| Apple Watch complication | Quick glance + tap-to-log from wrist |
| Refill reminders | Track pill counts, alert when running low |
| Multiple profiles | Full separate profiles for managing another person's medications |
| Widgets | iOS home/lock screen widget showing next due medication |
| Shortcuts integration | "Hey Siri, I took my metformin" |

---

## 11. Open Questions (Seeking Feedback)

1. **Onboarding depth:** Full walkthrough on first launch vs. just drop into the add-medication screen? Gen X typically hates onboarding, but context-setting might help with injection tracking setup.

2. **Adherence stats:** How much data visualization do users actually want? Simple % numbers vs. charts vs. nothing-by-default?

3. **Caregiver mode architecture:** CloudKit vs. a backend service? How much of a privacy concern is medication data sharing?

4. **HealthKit medication API:** In iOS 16, Apple added a Medications section to the Health app using a non-public API. What's the correct public HealthKit write target for logging medication doses from third-party apps?

5. **App icon concept:** Pill with synthwave aesthetic? Rx symbol? Abstract/geometric?

6. **Theme switching:** Instant switch vs. animated transition?

7. **Name validation:** "GenRx" confirmed not on App Store as of research date. Worth trademark search before going too far?

8. **Monetization:** Free? One-time purchase? Freemium (basic free, themes/stats paid)? Subscription feels wrong for this audience.

---

## 12. Competitive Analysis Notes

Existing apps in this space (MediSafe, MyTherapy, Roundhealth) skew toward:
- Clinical/sterile aesthetic
- Elderly or patient-caregiver focus
- Gamification (streaks, rewards)
- Overly complex onboarding

GenRx differentiates by being:
- Opinionated and personality-driven
- Aesthetically distinct (three 80s-inspired themes vs. generic blue medical UI)
- Focused on a specific, underserved demographic
- Snark as a feature, not a bug

---

*Spec authored via AI-assisted design session. All copy, UI decisions, and architecture subject to revision based on user testing and developer feedback.*
