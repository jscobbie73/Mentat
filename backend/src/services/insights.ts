import { pool } from "../config/database.js";
import { Insight, InsightType } from "../models/insight.js";
import { summarize, suggestResources } from "./ai.js";

/**
 * Generate insights for a fragment: a summary and related topic suggestions.
 * Stores them in the database and returns the generated insights.
 */
export async function generateInsights(
  userId: string,
  fragmentId: string,
): Promise<Insight[]> {
  // Fetch the fragment
  const frag = await pool.query(
    "SELECT title, content FROM fragments WHERE id = $1 AND user_id = $2",
    [fragmentId, userId],
  );
  if (frag.rows.length === 0) return [];

  const { title, content } = frag.rows[0];
  const fullText = `${title}\n${content}`;
  const insights: Insight[] = [];

  // Generate summary insight
  const summary = await summarize(fullText);
  if (summary) {
    const summaryRow = await storeInsight(userId, fragmentId, "summary", summary);
    insights.push(summaryRow);
  }

  // Generate related topic suggestions
  const suggestions = await suggestResources(content);
  for (const suggestion of suggestions) {
    const row = await storeInsight(
      userId,
      fragmentId,
      "relatedTopic",
      suggestion,
    );
    insights.push(row);
  }

  return insights;
}

/**
 * List insights for a user, optionally filtered by fragment.
 */
export async function listInsights(
  userId: string,
  fragmentId?: string,
  limit = 50,
  offset = 0,
): Promise<Insight[]> {
  let query: string;
  let params: unknown[];

  if (fragmentId) {
    query = `SELECT * FROM insights
             WHERE user_id = $1 AND fragment_id = $2
             ORDER BY created_at DESC
             LIMIT $3 OFFSET $4`;
    params = [userId, fragmentId, limit, offset];
  } else {
    query = `SELECT * FROM insights
             WHERE user_id = $1
             ORDER BY created_at DESC
             LIMIT $2 OFFSET $3`;
    params = [userId, limit, offset];
  }

  const result = await pool.query(query, params);
  return result.rows.map(rowToInsight);
}

async function storeInsight(
  userId: string,
  fragmentId: string,
  insightType: InsightType,
  content: string,
  metadata: Record<string, unknown> = {},
): Promise<Insight> {
  const result = await pool.query(
    `INSERT INTO insights (user_id, fragment_id, insight_type, content, metadata)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING *`,
    [userId, fragmentId, insightType, content, JSON.stringify(metadata)],
  );
  return rowToInsight(result.rows[0]);
}

function rowToInsight(row: Record<string, unknown>): Insight {
  return {
    id: row.id as string,
    userId: row.user_id as string,
    fragmentId: row.fragment_id as string | null,
    insightType: row.insight_type as InsightType,
    content: row.content as string,
    metadata: (row.metadata ?? {}) as Record<string, unknown>,
    createdAt: new Date(row.created_at as string),
  };
}
