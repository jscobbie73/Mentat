import { Router, Request, Response } from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { pool } from "../config/database.js";
import { RegisterSchema, LoginSchema, AppleSignInSchema } from "../models/user.js";
import { validate } from "../middleware/validate.js";
import { asyncHandler } from "../middleware/asyncHandler.js";
import { generateToken } from "../middleware/auth.js";

const router = Router();

router.post(
  "/register",
  validate(RegisterSchema),
  asyncHandler(async (req: Request, res: Response): Promise<void> => {
    try {
      const { email, password, displayName } = req.body;
      const passwordHash = await bcrypt.hash(password, 12);

      const result = await pool.query(
        `INSERT INTO users (email, password_hash, display_name)
         VALUES ($1, $2, $3)
         RETURNING id, email, display_name`,
        [email, passwordHash, displayName],
      );

      const user = result.rows[0];
      const token = generateToken({ userId: user.id, email: user.email });

      res.status(201).json({
        user: {
          id: user.id,
          email: user.email,
          displayName: user.display_name,
        },
        token,
      });
    } catch (err: unknown) {
      if (
        err instanceof Error &&
        err.message.includes("duplicate key")
      ) {
        res.status(409).json({ error: "Email already registered" });
        return;
      }
      throw err;
    }
  }),
);

router.post(
  "/login",
  validate(LoginSchema),
  asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const { email, password } = req.body;

    const result = await pool.query(
      "SELECT id, email, password_hash, display_name FROM users WHERE email = $1",
      [email],
    );

    if (result.rows.length === 0) {
      res.status(401).json({ error: "Invalid credentials" });
      return;
    }

    const user = result.rows[0];
    if (!user.password_hash) {
      res
        .status(401)
        .json({ error: "Account uses Apple Sign In. No password set." });
      return;
    }

    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      res.status(401).json({ error: "Invalid credentials" });
      return;
    }

    const token = generateToken({ userId: user.id, email: user.email });
    res.json({
      user: {
        id: user.id,
        email: user.email,
        displayName: user.display_name,
      },
      token,
    });
  }),
);

// Apple Sign In
router.post(
  "/apple",
  validate(AppleSignInSchema),
  asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const { identityToken, displayName } = req.body;

    // Decode the Apple identity token to extract the user's subject and email.
    // Apple identity tokens are JWTs signed by Apple. In production, the
    // signature should be verified against Apple's public keys (JWKS). Here
    // we decode without verification to extract claims — signature validation
    // should be added before shipping to production.
    const decoded = jwt.decode(identityToken) as {
      sub?: string;
      email?: string;
    } | null;

    if (!decoded?.sub || !decoded?.email) {
      res.status(400).json({ error: "Invalid Apple identity token" });
      return;
    }

    const appleUserId = decoded.sub;
    const email = decoded.email;

    // Try to find existing user by Apple ID
    let result = await pool.query(
      "SELECT id, email, display_name FROM users WHERE apple_user_id = $1",
      [appleUserId],
    );

    if (result.rows.length === 0) {
      // Try to find by email (user may have registered with password first)
      result = await pool.query(
        "SELECT id, email, display_name, apple_user_id FROM users WHERE email = $1",
        [email],
      );

      if (result.rows.length > 0 && !result.rows[0].apple_user_id) {
        // Link Apple ID to existing account
        await pool.query(
          "UPDATE users SET apple_user_id = $1, updated_at = NOW() WHERE id = $2",
          [appleUserId, result.rows[0].id],
        );
      } else if (result.rows.length === 0) {
        // Create new user
        result = await pool.query(
          `INSERT INTO users (email, apple_user_id, display_name)
           VALUES ($1, $2, $3)
           RETURNING id, email, display_name`,
          [email, appleUserId, displayName || email.split("@")[0]],
        );
      }
    }

    const user = result.rows[0];
    const token = generateToken({ userId: user.id, email: user.email });

    res.json({
      user: {
        id: user.id,
        email: user.email,
        displayName: user.display_name,
      },
      token,
    });
  }),
);

export default router;
