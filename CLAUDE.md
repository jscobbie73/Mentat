# Mentat - AI-Powered Second Brain

## Development Environment

- **Cloud workspace**: `/home/user/Mentat/` (where Claude Code runs)
- **Local Mac workspace**: `/Users/jasonscobbie/Desktop/Code/Mentat/`
- **Branch**: `claude/init-mentat-repo-xuBHq`
- **Sync workflow**: Code is written in the cloud workspace, pushed to GitHub, then pulled locally with `git pull`

## Architecture

- **Backend**: TypeScript/Node.js + Express + PostgreSQL (pgvector) + OpenAI
- **Apple clients**: Swift 6 + SwiftUI + SwiftData (iOS 18+, macOS 15+)
- **Safari extension**: Manifest V3 web extension with native messaging
- **Shared types**: TypeScript interfaces in `/shared/src/index.ts`

## Key Directories

| Path | Purpose |
|------|---------|
| `backend/src/routes/` | Express API endpoints (auth, fragments, collections, insights) |
| `backend/src/services/` | Business logic (AI, fragments, collections, insights) |
| `backend/src/models/` | Zod validation schemas |
| `backend/src/middleware/` | Auth, validation, async error handling |
| `apple/Shared/` | Swift code shared across all Apple targets |
| `apple/Shared/Networking/` | APIClient + API request/response models |
| `apple/Shared/Services/` | AuthManager, FragmentStore, CollectionStore |
| `apple/Shared/Views/` | Shared SwiftUI views (AuthGateView, AddToCollectionSheet) |
| `apple/MentatiOS/Sources/` | iOS/iPad app views |
| `apple/MentatMac/Sources/` | macOS app views |
| `apple/MentatSafariExtension/` | Safari web extension (JS + Swift handler) |
| `apple/MentatShareExtension/` | iOS Share extension |

## Conventions

- Backend routes use `asyncHandler()` wrapper for error forwarding
- All API responses use snake_case (Swift APIClient converts to/from camelCase)
- Local-first: SwiftData saves locally, then syncs to backend asynchronously
- Auth tokens stored in Keychain (`com.mentat.app` service)
- Safari extension uses native message ID `com.mentat.app.Extension`
