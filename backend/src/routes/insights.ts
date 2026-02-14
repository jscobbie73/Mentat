import { Router, Request, Response } from "express";
import { authenticate } from "../middleware/auth.js";
import { asyncHandler } from "../middleware/asyncHandler.js";
import { generateInsights, listInsights } from "../services/insights.js";

const router = Router();

router.use(authenticate);

// List user's insights (optionally filtered by fragment)
router.get("/", asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const fragmentId = req.query.fragmentId as string | undefined;
  const limit = Math.min(Number(req.query.limit) || 50, 100);
  const offset = Number(req.query.offset) || 0;

  const insights = await listInsights(req.user!.userId, fragmentId, limit, offset);
  res.json({ insights, limit, offset });
}));

// Generate insights for a specific fragment
router.post(
  "/generate/:fragmentId",
  asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const insights = await generateInsights(
      req.user!.userId,
      req.params.fragmentId,
    );
    if (insights.length === 0) {
      res.status(404).json({ error: "Fragment not found or no insights generated" });
      return;
    }
    res.status(201).json({ insights });
  }),
);

export default router;
