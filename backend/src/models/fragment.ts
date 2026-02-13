import { z } from "zod";

export const FragmentSourceType = z.enum([
  "note",
  "highlight",
  "bookmark",
  "article",
  "image",
  "file",
  "share",
]);
export type FragmentSourceType = z.infer<typeof FragmentSourceType>;

export const CreateFragmentSchema = z.object({
  title: z.string().min(1).max(500),
  content: z.string().min(1),
  sourceUrl: z.string().url().optional(),
  sourceType: FragmentSourceType.default("note"),
  metadata: z.record(z.unknown()).optional(),
  collectionId: z.string().uuid().optional(),
});

export const UpdateFragmentSchema = CreateFragmentSchema.partial();

export interface Fragment {
  id: string;
  userId: string;
  title: string;
  content: string;
  sourceUrl: string | null;
  sourceType: FragmentSourceType;
  embedding: number[] | null;
  metadata: Record<string, unknown>;
  createdAt: Date;
  updatedAt: Date;
}

export interface Connection {
  id: string;
  userId: string;
  fragmentAId: string;
  fragmentBId: string;
  similarity: number;
  aiSummary: string | null;
  createdAt: Date;
}

export interface Insight {
  id: string;
  userId: string;
  fragmentId: string | null;
  insightType: string;
  content: string;
  metadata: Record<string, unknown>;
  createdAt: Date;
}
