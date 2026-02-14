/**
 * Shared types for the Mentat platform.
 * Used by the backend and any future web clients.
 */

// Fragment types
export type FragmentSourceType =
  | "note"
  | "highlight"
  | "bookmark"
  | "article"
  | "image"
  | "file"
  | "share";

export interface Fragment {
  id: string;
  userId: string;
  title: string;
  content: string;
  sourceUrl: string | null;
  sourceType: FragmentSourceType;
  metadata: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
}

export interface CreateFragmentInput {
  title: string;
  content: string;
  sourceUrl?: string;
  sourceType?: FragmentSourceType;
  metadata?: Record<string, unknown>;
  collectionId?: string;
}

export interface UpdateFragmentInput {
  title?: string;
  content?: string;
  sourceUrl?: string;
  sourceType?: FragmentSourceType;
  metadata?: Record<string, unknown>;
}

// Collection types
export interface Collection {
  id: string;
  userId: string;
  name: string;
  description: string | null;
  createdAt: string;
  updatedAt: string;
}

// Connection types
export interface Connection {
  id: string;
  fragmentAId: string;
  fragmentBId: string;
  similarity: number;
  aiSummary: string | null;
  createdAt: string;
}

// Insight types
export type InsightType = "summary" | "theme" | "suggestion" | "relatedTopic";

export interface Insight {
  id: string;
  fragmentId: string | null;
  insightType: InsightType;
  content: string;
  metadata: Record<string, unknown>;
  createdAt: string;
}

// Collection input types
export interface CreateCollectionInput {
  name: string;
  description?: string;
}

export interface UpdateCollectionInput {
  name?: string;
  description?: string | null;
}

// Connection result (as returned by the API)
export interface ConnectionResult {
  id: string | null;
  fragmentId: string;
  title: string;
  content: string;
  sourceType: FragmentSourceType;
  similarity: number;
  aiSummary: string | null;
  fragmentCreatedAt: string;
}

// Auth types
export interface AuthResponse {
  user: {
    id: string;
    email: string;
    displayName: string;
  };
  token: string;
}

// API response wrappers
export interface PaginatedResponse<T> {
  data: T[];
  limit: number;
  offset: number;
  total?: number;
}

export interface SearchResult {
  id: string;
  title: string;
  content: string;
  similarity: number;
}
