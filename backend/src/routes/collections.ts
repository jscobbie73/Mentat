import { Router, Request, Response } from "express";
import { authenticate } from "../middleware/auth.js";
import { validate } from "../middleware/validate.js";
import { asyncHandler } from "../middleware/asyncHandler.js";
import {
  CreateCollectionSchema,
  UpdateCollectionSchema,
  AddFragmentToCollectionSchema,
} from "../models/collection.js";
import {
  createCollection,
  listCollections,
  getCollection,
  getCollectionFragments,
  updateCollection,
  deleteCollection,
  addFragmentToCollection,
  removeFragmentFromCollection,
} from "../services/collections.js";

const router = Router();

router.use(authenticate);

// Create a collection
router.post(
  "/",
  validate(CreateCollectionSchema),
  asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const collection = await createCollection(req.user!.userId, req.body);
    res.status(201).json(collection);
  }),
);

// List user's collections
router.get("/", asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const collections = await listCollections(req.user!.userId);
  res.json({ collections });
}));

// Get a single collection with its fragments
router.get("/:id", asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const collection = await getCollection(req.user!.userId, req.params.id);
  if (!collection) {
    res.status(404).json({ error: "Collection not found" });
    return;
  }

  const limit = Math.min(Number(req.query.limit) || 50, 100);
  const offset = Number(req.query.offset) || 0;
  const fragments = await getCollectionFragments(
    req.user!.userId,
    req.params.id,
    limit,
    offset,
  );

  res.json({ ...collection, fragments, limit, offset });
}));

// Update a collection
router.patch(
  "/:id",
  validate(UpdateCollectionSchema),
  asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const collection = await updateCollection(
      req.user!.userId,
      req.params.id,
      req.body,
    );
    if (!collection) {
      res.status(404).json({ error: "Collection not found" });
      return;
    }
    res.json(collection);
  }),
);

// Delete a collection
router.delete("/:id", asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const deleted = await deleteCollection(req.user!.userId, req.params.id);
  if (!deleted) {
    res.status(404).json({ error: "Collection not found" });
    return;
  }
  res.status(204).send();
}));

// Add a fragment to a collection
router.post(
  "/:id/fragments",
  validate(AddFragmentToCollectionSchema),
  asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const added = await addFragmentToCollection(
      req.user!.userId,
      req.params.id,
      req.body.fragmentId,
    );
    if (!added) {
      res
        .status(404)
        .json({ error: "Collection or fragment not found" });
      return;
    }
    res.status(201).json({ success: true });
  }),
);

// Remove a fragment from a collection
router.delete(
  "/:id/fragments/:fragmentId",
  asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const removed = await removeFragmentFromCollection(
      req.user!.userId,
      req.params.id,
      req.params.fragmentId,
    );
    if (!removed) {
      res
        .status(404)
        .json({ error: "Collection or fragment not found" });
      return;
    }
    res.status(204).send();
  }),
);

export default router;
