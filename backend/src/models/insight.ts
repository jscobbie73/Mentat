import { z } from "zod";

export const InsightTypeEnum = z.enum([
  "summary",
  "theme",
  "suggestion",
  "relatedTopic",
]);
export type InsightType = z.infer<typeof InsightTypeEnum>;

export interface Insight {
  id: string;
  userId: string;
  fragmentId: string | null;
  insightType: InsightType;
  content: string;
  metadata: Record<string, unknown>;
  createdAt: Date;
}
