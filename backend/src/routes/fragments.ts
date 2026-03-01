import { Router, Request, Response } from "express";
import { authenticate } from "../middleware/auth.js";
import { validate } from "../middleware/validate.js";
import { asyncHandler } from "../middleware/asyncHandler.js";
import { CreateFragmentSchema, UpdateFragmentSchema } from "../models/fragment.js";
import {
  createFragment,
  searchFragments,
  findSimilar,
} from "../services/fragments.js";
import { suggestResources } from "../services/ai.js";
import { pool } from "../config/database.js";

const router = Router();

// All fragment routes require authentication
router.use(authenticate);

// Create a new fragment
router.post(
  "/",
  validate(CreateFragmentSchema),
  asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const fragment = await createFragment(req.user!.userId, req.body);
    res.status(201).json(fragment);
  }),
);

// List user's fragments (paginated)
router.get("/", asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const limit = Math.min(Number(req.query.limit) || 50, 100);
  const offset = Number(req.query.offset) || 0;

  const result = await pool.query(
    `SELECT id, user_id, title, content, source_url, source_type, metadata, created_at, updated_at
     FROM fragments
     WHERE user_id = $1
     ORDER BY created_at DESC
     LIMIT $2 OFFSET $3`,
    [req.user!.userId, limit, offset],
  );

  res.json({ fragments: result.rows, limit, offset });
}));

// Search fragments semantically
router.get("/search", asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const query = req.query.q as string;
  if (!query) {
    res.status(400).json({ error: "Query parameter 'q' is required" });
    return;
  }

  const results = await searchFragments(req.user!.userId, query);
  res.json({ results });
}));

// Get a single fragment
router.get("/:id", asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await pool.query(
    "SELECT * FROM fragments WHERE id = $1 AND user_id = $2",
    [req.params.id, req.user!.userId],
  );

  if (result.rows.length === 0) {
    res.status(404).json({ error: "Fragment not found" });
    return;
  }
  res.json(result.rows[0]);
}));

// Update a fragment
router.patch(
  "/:id",
  validate(UpdateFragmentSchema),
  asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const { title, content, sourceUrl, sourceType, metadata } = req.body;

    const result = await pool.query(
      `UPDATE fragments
       SET title = COALESCE($1, title),
           content = COALESCE($2, content),
           source_url = COALESCE($3, source_url),
           source_type = COALESCE($4, source_type),
           metadata = COALESCE($5, metadata),
           updated_at = NOW()
       WHERE id = $6 AND user_id = $7
       RETURNING *`,
      [
        title,
        content,
        sourceUrl,
        sourceType,
        metadata ? JSON.stringify(metadata) : null,
        req.params.id,
        req.user!.userId,
      ],
    );

    if (result.rows.length === 0) {
      res.status(404).json({ error: "Fragment not found" });
      return;
    }
    res.json(result.rows[0]);
  }),
);

// Delete a fragment
router.delete("/:id", asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await pool.query(
    "DELETE FROM fragments WHERE id = $1 AND user_id = $2 RETURNING id",
    [req.params.id, req.user!.userId],
  );

  if (result.rows.length === 0) {
    res.status(404).json({ error: "Fragment not found" });
    return;
  }
  res.status(204).send();
}));

// Get connections for a fragment (stored + live similarity)
router.get(
  "/:id/connections",
  asyncHandler(async (req: Request, res: Response): Promise<void> => {
    // First, return stored connections that include AI summaries
    const stored = await pool.query(
      `SELECT c.id, c.similarity, c.ai_summary,
              f.id AS fragment_id, f.title, f.content, f.source_type, f.created_at AS fragment_created_at
       FROM connections c
       JOIN fragments f ON f.id = CASE
         WHEN c.fragment_a_id = $1 THEN c.fragment_b_id
         ELSE c.fragment_a_id
       END
       WHERE (c.fragment_a_id = $1 OR c.fragment_b_id = $1)
         AND c.user_id = $2
       ORDER BY c.similarity DESC`,
      [req.params.id, req.user!.userId],
    );

    if (stored.rows.length > 0) {
      const connections = stored.rows.map((row) => ({
        id: row.id,
        fragmentId: row.fragment_id,
        title: row.title,
        content: row.content,
        sourceType: row.source_type,
        similarity: row.similarity,
        aiSummary: row.ai_summary,
        fragmentCreatedAt: row.fragment_created_at,
      }));
      res.json({ connections });
      return;
    }

    // Fallback: live similarity search if no stored connections yet
    const similar = await findSimilar(req.user!.userId, req.params.id);
    const connections = similar.map((s) => ({
      id: null,
      fragmentId: s.id,
      title: s.title,
      content: s.content,
      sourceType: s.sourceType,
      similarity: s.similarity,
      aiSummary: null,
      fragmentCreatedAt: s.createdAt,
    }));
    res.json({ connections });
  }),
);

// Get AI suggestions for a fragment
router.get(
  "/:id/suggestions",
  asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const result = await pool.query(
      "SELECT content FROM fragments WHERE id = $1 AND user_id = $2",
      [req.params.id, req.user!.userId],
    );

    if (result.rows.length === 0) {
      res.status(404).json({ error: "Fragment not found" });
      return;
    }

    const suggestions = await suggestResources(result.rows[0].content);
    res.json({ suggestions });
  }),
);

export default router;
