# Mentat

**Your AI-powered second brain.**

Mentat captures, connects, and surfaces your knowledge across all your devices. It stores information you collect and uses AI to find connections, generate summaries, and suggest where to learn more.

> *"It is by will alone I set my mind in motion."* — Mentat mantra, Dune

## Architecture

Mentat is a multi-platform application consisting of:

| Component | Location | Description |
|-----------|----------|-------------|
| **SAAS Backend** | `backend/` | TypeScript/Node.js API server with PostgreSQL and vector storage |
| **Mac App** | `apple/MentatMac/` | Native macOS application (SwiftUI) |
| **iOS App** | `apple/MentatiOS/` | Universal iPhone & iPad application (SwiftUI) |
| **Safari Extension** | `apple/MentatSafariExtension/` | Browser extension to capture web content |
| **Share Extension** | `apple/MentatShareExtension/` | iOS system share sheet integration |
| **Shared (Apple)** | `apple/Shared/` | Shared Swift code across all Apple targets |
| **Shared (Types)** | `shared/` | Shared TypeScript types and schemas |

## Core Concepts

- **Fragments**: Individual pieces of captured information (notes, highlights, bookmarks, files)
- **Connections**: AI-discovered relationships between fragments
- **Collections**: User-organized groups of fragments
- **Insights**: AI-generated summaries, themes, and suggestions

## Getting Started

### Backend

```bash
cd backend
npm install
cp .env.example .env   # configure your environment
npm run dev
```

### Apple Apps

Open `apple/Mentat.xcodeproj` in Xcode 16+ and select the desired target scheme.

## Tech Stack

- **Backend**: TypeScript, Node.js, Express, PostgreSQL, pgvector, Redis
- **AI**: OpenAI embeddings + LLM for connections and summaries
- **Apple**: Swift 6, SwiftUI, SwiftData, Combine
- **Auth**: JWT + OAuth 2.0 (Sign in with Apple)

## Project Structure

```
Mentat/
├── backend/                 # SAAS API server
│   ├── src/
│   │   ├── config/          # App configuration
│   │   ├── middleware/       # Auth, validation, error handling
│   │   ├── models/          # Database models & schemas
│   │   ├── routes/          # API route handlers
│   │   └── services/        # Business logic & AI services
│   └── package.json
├── apple/                   # All Apple platform code
│   ├── Shared/              # Cross-target Swift code
│   ├── MentatMac/           # macOS app target
│   ├── MentatiOS/           # iOS app target
│   ├── MentatSafariExtension/  # Safari extension target
│   └── MentatShareExtension/   # Share extension target
└── shared/                  # Shared TypeScript types
```

## License

Proprietary. All rights reserved.
