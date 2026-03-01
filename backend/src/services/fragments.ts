import { pool } from "../config/database.js";
import { Fragment } from "../models/fragment.js";
import { generateEmbedding, explainConnection } from "./ai.js";

/**
 * Create a new fragment and generate its embedding.
 */
export async function createFragment(
  userId: string,
  data: {
    title: string;
    content: string;
    sourceUrl?: string;
    sourceType?: string;
    metadata?: Record<string, unknown>;
  },
): Promise<Fragment> {
  const embedding = await generateEmbedding(`${data.title}\n${data.content}`);
  const embeddingStr = `[${embedding.join(",")}]`;

  const result = await pool.query(
    `INSERT INTO fragments (user_id, title, content, source_url, source_type, embedding, metadata)
     VALUES ($1, $2, $3, $4, $5, $6::vector, $7)
     RETURNING *`,
    [
      userId,
      data.title,
      data.content,
      data.sourceUrl ?? null,
      data.sourceType ?? "note",
      embeddingStr,
      JSON.stringify(data.metadata ?? {}),
    ],
  );

  const fragment = rowToFragment(result.rows[0]);

  // Fire-and-forget: discover connections to existing fragments
  discoverConnections(userId, fragment.id).catch(console.error);

  return fragment;
}

/**
 * Find fragments similar to the given fragment by vector similarity.
 */
export async function findSimilar(
  userId: string,
  fragmentId: string,
  limit = 10,
): Promise<Array<Fragment & { similarity: number }>> {
  const result = await pool.query(
    `SELECT f.*, 1 - (f.embedding <=> ref.embedding) AS similarity
     FROM fragments f, fragments ref
     WHERE ref.id = $1
       AND f.user_id = $2
       AND f.id != $1
       AND f.embedding IS NOT NULL
     ORDER BY f.embedding <=> ref.embedding
     LIMIT $3`,
    [fragmentId, userId, limit],
  );

  return result.rows.map((row: Record<string, unknown>) => ({
    ...rowToFragment(row),
    similarity: row.similarity as number,
  }));
}

/**
 * Search fragments by semantic similarity to a query string.
 */
export async function searchFragments(
  userId: string,
  query: string,
  limit = 20,
): Promise<Array<Fragment & { similarity: number }>> {
  const embedding = await generateEmbedding(query);
  const embeddingStr = `[${embedding.join(",")}]`;

  const result = await pool.query(
    `SELECT *, 1 - (embedding <=> $1::vector) AS similarity
     FROM fragments
     WHERE user_id = $2
       AND embedding IS NOT NULL
     ORDER BY embedding <=> $1::vector
     LIMIT $3`,
    [embeddingStr, userId, limit],
  );

  return result.rows.map((row: Record<string, unknown>) => ({
    ...rowToFragment(row),
    similarity: row.similarity as number,
  }));
}

/**
 * Discover and store connections between a new fragment and existing ones.
 */
async function discoverConnections(
  userId: string,
  fragmentId: string,
): Promise<void> {
  const similar = await findSimilar(userId, fragmentId, 5);
  const threshold = 0.75;

  for (const match of similar) {
    if (match.similarity < threshold) continue;

    const source = await pool.query("SELECT content FROM fragments WHERE id = $1", [fragmentId]);
    const summary = await explainConnection(
      source.rows[0].content,
      match.content,
    );

    await pool.query(
      `INSERT INTO connections (user_id, fragment_a_id, fragment_b_id, similarity, ai_summary)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (fragment_a_id, fragment_b_id) DO NOTHING`,
      [userId, fragmentId, match.id, match.similarity, summary],
    );
  }
}

function rowToFragment(row: Record<string, unknown>): Fragment {
  return {
    id: row.id as string,
    userId: row.user_id as string,
    title: row.title as string,
    content: row.content as string,
    sourceUrl: row.source_url as string | null,
    sourceType: row.source_type as Fragment["sourceType"],
    embedding: row.embedding as number[] | null,
    metadata: (row.metadata ?? {}) as Record<string, unknown>,
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
  };
}
