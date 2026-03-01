import { describe, it, expect } from "vitest";
import { CreateFragmentSchema, UpdateFragmentSchema } from "../models/fragment.js";
import { RegisterSchema, LoginSchema, AppleSignInSchema } from "../models/user.js";
import {
  CreateCollectionSchema,
  UpdateCollectionSchema,
  AddFragmentToCollectionSchema,
} from "../models/collection.js";

describe("Fragment schemas", () => {
  it("validates a valid create fragment request", () => {
    const result = CreateFragmentSchema.safeParse({
      title: "Test Fragment",
      content: "This is a test fragment with some content.",
      sourceType: "note",
    });
    expect(result.success).toBe(true);
  });

  it("rejects empty title", () => {
    const result = CreateFragmentSchema.safeParse({
      title: "",
      content: "Some content",
      sourceType: "note",
    });
    expect(result.success).toBe(false);
  });

  it("rejects invalid source type", () => {
    const result = CreateFragmentSchema.safeParse({
      title: "Test",
      content: "Some content",
      sourceType: "invalid_type",
    });
    expect(result.success).toBe(false);
  });

  it("allows all valid source types", () => {
    const validTypes = ["note", "highlight", "bookmark", "article", "image", "file", "share"];
    for (const type of validTypes) {
      const result = CreateFragmentSchema.safeParse({
        title: "Test",
        content: "Content",
        sourceType: type,
      });
      expect(result.success, `Expected ${type} to be valid`).toBe(true);
    }
  });

  it("validates partial update", () => {
    const result = UpdateFragmentSchema.safeParse({
      title: "Updated Title",
    });
    expect(result.success).toBe(true);
  });

  it("allows empty update object", () => {
    const result = UpdateFragmentSchema.safeParse({});
    expect(result.success).toBe(true);
  });
});

describe("User schemas", () => {
  it("validates a valid register request", () => {
    const result = RegisterSchema.safeParse({
      email: "user@example.com",
      password: "securepassword123",
      displayName: "Test User",
    });
    expect(result.success).toBe(true);
  });

  it("rejects invalid email", () => {
    const result = RegisterSchema.safeParse({
      email: "not-an-email",
      password: "securepassword123",
      displayName: "Test User",
    });
    expect(result.success).toBe(false);
  });

  it("rejects short password", () => {
    const result = RegisterSchema.safeParse({
      email: "user@example.com",
      password: "short",
      displayName: "Test User",
    });
    expect(result.success).toBe(false);
  });

  it("validates a valid login request", () => {
    const result = LoginSchema.safeParse({
      email: "user@example.com",
      password: "securepassword123",
    });
    expect(result.success).toBe(true);
  });

  it("validates Apple Sign In request", () => {
    const result = AppleSignInSchema.safeParse({
      identityToken: "eyJhbGciOiJSUzI1NiJ9.test.token",
      authorizationCode: "abc123",
    });
    expect(result.success).toBe(true);
  });
});

describe("Collection schemas", () => {
  it("validates a valid create collection request", () => {
    const result = CreateCollectionSchema.safeParse({
      name: "My Collection",
      description: "A test collection",
    });
    expect(result.success).toBe(true);
  });

  it("rejects empty collection name", () => {
    const result = CreateCollectionSchema.safeParse({
      name: "",
    });
    expect(result.success).toBe(false);
  });

  it("allows collection without description", () => {
    const result = CreateCollectionSchema.safeParse({
      name: "My Collection",
    });
    expect(result.success).toBe(true);
  });

  it("validates partial collection update", () => {
    const result = UpdateCollectionSchema.safeParse({
      name: "Updated Name",
    });
    expect(result.success).toBe(true);
  });

  it("validates add fragment to collection", () => {
    const result = AddFragmentToCollectionSchema.safeParse({
      fragmentId: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
    });
    expect(result.success).toBe(true);
  });

  it("rejects invalid UUID for fragment", () => {
    const result = AddFragmentToCollectionSchema.safeParse({
      fragmentId: "not-a-uuid",
    });
    expect(result.success).toBe(false);
  });
});
