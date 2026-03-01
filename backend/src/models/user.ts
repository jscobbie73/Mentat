import { z } from "zod";

export const RegisterSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  displayName: z.string().min(1).max(100),
});

export const LoginSchema = z.object({
  email: z.string().email(),
  password: z.string(),
});

export const AppleSignInSchema = z.object({
  identityToken: z.string(),
  authorizationCode: z.string(),
  displayName: z.string().optional(),
});

export interface User {
  id: string;
  email: string;
  passwordHash: string | null;
  appleUserId: string | null;
  displayName: string;
  createdAt: Date;
  updatedAt: Date;
}
