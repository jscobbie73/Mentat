import { z } from "zod";

export const CreateCollectionSchema = z.object({
  name: z.string().min(1).max(200),
  description: z.string().max(1000).optional(),
});

export const UpdateCollectionSchema = z.object({
  name: z.string().min(1).max(200).optional(),
  description: z.string().max(1000).nullable().optional(),
});

export const AddFragmentToCollectionSchema = z.object({
  fragmentId: z.string().uuid(),
});

export interface Collection {
  id: string;
  userId: string;
  name: string;
  description: string | null;
  createdAt: Date;
  updatedAt: Date;
}
