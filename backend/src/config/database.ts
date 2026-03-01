import { Pool } from "pg";
import { config } from "./index.js";

export const pool = new Pool({
  connectionString: config.DATABASE_URL,
});

/**
 * Initialize database with required extensions and tables.
 */
export async function initDatabase(): Promise<void> {
  const client = await pool.connect();
  try {
    await client.query("CREATE EXTENSION IF NOT EXISTS vector");
    await client.query("CREATE EXTENSION IF NOT EXISTS pgcrypto");

    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT,
        apple_user_id TEXT UNIQUE,
        display_name TEXT NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS fragments (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        source_url TEXT,
        source_type TEXT NOT NULL DEFAULT 'note',
        embedding vector(1536),
        metadata JSONB DEFAULT '{}',
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS collections (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        description TEXT,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS collection_fragments (
        collection_id UUID NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
        fragment_id UUID NOT NULL REFERENCES fragments(id) ON DELETE CASCADE,
        added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        PRIMARY KEY (collection_id, fragment_id)
      );

      CREATE TABLE IF NOT EXISTS connections (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        fragment_a_id UUID NOT NULL REFERENCES fragments(id) ON DELETE CASCADE,
        fragment_b_id UUID NOT NULL REFERENCES fragments(id) ON DELETE CASCADE,
        similarity REAL NOT NULL,
        ai_summary TEXT,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        UNIQUE(fragment_a_id, fragment_b_id)
      );

      CREATE TABLE IF NOT EXISTS insights (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        fragment_id UUID REFERENCES fragments(id) ON DELETE CASCADE,
        insight_type TEXT NOT NULL,
        content TEXT NOT NULL,
        metadata JSONB DEFAULT '{}',
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );

      CREATE INDEX IF NOT EXISTS idx_fragments_user ON fragments(user_id);
      CREATE INDEX IF NOT EXISTS idx_fragments_embedding ON fragments
        USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
      CREATE INDEX IF NOT EXISTS idx_connections_user ON connections(user_id);
      CREATE INDEX IF NOT EXISTS idx_insights_user ON insights(user_id);
    `);
  } finally {
    client.release();
  }
}
