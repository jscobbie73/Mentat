import { pool } from "../config/database.js";
import { Collection } from "../models/collection.js";
import { Fragment } from "../models/fragment.js";

export async function createCollection(
  userId: string,
  data: { name: string; description?: string },
): Promise<Collection> {
  const result = await pool.query(
    `INSERT INTO collections (user_id, name, description)
     VALUES ($1, $2, $3)
     RETURNING *`,
    [userId, data.name, data.description ?? null],
  );
  return rowToCollection(result.rows[0]);
}

export async function listCollections(userId: string): Promise<Collection[]> {
  const result = await pool.query(
    `SELECT * FROM collections WHERE user_id = $1 ORDER BY created_at DESC`,
    [userId],
  );
  return result.rows.map(rowToCollection);
}

export async function getCollection(
  userId: string,
  collectionId: string,
): Promise<Collection | null> {
  const result = await pool.query(
    `SELECT * FROM collections WHERE id = $1 AND user_id = $2`,
    [collectionId, userId],
  );
  return result.rows.length > 0 ? rowToCollection(result.rows[0]) : null;
}

export async function getCollectionFragments(
  userId: string,
  collectionId: string,
  limit: number,
  offset: number,
): Promise<Fragment[]> {
  const result = await pool.query(
    `SELECT f.id, f.user_id, f.title, f.content, f.source_url, f.source_type, f.metadata, f.created_at, f.updated_at
     FROM fragments f
     JOIN collection_fragments cf ON cf.fragment_id = f.id
     WHERE cf.collection_id = $1 AND f.user_id = $2
     ORDER BY cf.added_at DESC
     LIMIT $3 OFFSET $4`,
    [collectionId, userId, limit, offset],
  );
  return result.rows.map(rowToFragment);
}

export async function updateCollection(
  userId: string,
  collectionId: string,
  data: { name?: string; description?: string | null },
): Promise<Collection | null> {
  const result = await pool.query(
    `UPDATE collections
     SET name = COALESCE($1, name),
         description = COALESCE($2, description),
         updated_at = NOW()
     WHERE id = $3 AND user_id = $4
     RETURNING *`,
    [data.name ?? null, data.description ?? null, collectionId, userId],
  );
  return result.rows.length > 0 ? rowToCollection(result.rows[0]) : null;
}

export async function deleteCollection(
  userId: string,
  collectionId: string,
): Promise<boolean> {
  const result = await pool.query(
    `DELETE FROM collections WHERE id = $1 AND user_id = $2 RETURNING id`,
    [collectionId, userId],
  );
  return result.rows.length > 0;
}

export async function addFragmentToCollection(
  userId: string,
  collectionId: string,
  fragmentId: string,
): Promise<boolean> {
  // Verify both belong to this user
  const check = await pool.query(
    `SELECT
       (SELECT id FROM collections WHERE id = $1 AND user_id = $3) AS coll_id,
       (SELECT id FROM fragments WHERE id = $2 AND user_id = $3) AS frag_id`,
    [collectionId, fragmentId, userId],
  );
  if (!check.rows[0].coll_id || !check.rows[0].frag_id) {
    return false;
  }

  await pool.query(
    `INSERT INTO collection_fragments (collection_id, fragment_id)
     VALUES ($1, $2)
     ON CONFLICT (collection_id, fragment_id) DO NOTHING`,
    [collectionId, fragmentId],
  );
  return true;
}

export async function removeFragmentFromCollection(
  userId: string,
  collectionId: string,
  fragmentId: string,
): Promise<boolean> {
  // Verify collection belongs to user
  const check = await pool.query(
    `SELECT id FROM collections WHERE id = $1 AND user_id = $2`,
    [collectionId, userId],
  );
  if (check.rows.length === 0) return false;

  const result = await pool.query(
    `DELETE FROM collection_fragments
     WHERE collection_id = $1 AND fragment_id = $2
     RETURNING collection_id`,
    [collectionId, fragmentId],
  );
  return result.rows.length > 0;
}

function rowToCollection(row: Record<string, unknown>): Collection {
  return {
    id: row.id as string,
    userId: row.user_id as string,
    name: row.name as string,
    description: row.description as string | null,
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
  };
}

function rowToFragment(row: Record<string, unknown>): Fragment {
  return {
    id: row.id as string,
    userId: row.user_id as string,
    title: row.title as string,
    content: row.content as string,
    sourceUrl: row.source_url as string | null,
    sourceType: row.source_type as Fragment["sourceType"],
    embedding: null,
    metadata: (row.metadata ?? {}) as Record<string, unknown>,
    createdAt: new Date(row.created_at as string),
    updatedAt: new Date(row.updated_at as string),
  };
}
