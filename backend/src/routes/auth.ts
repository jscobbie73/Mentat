import { Router, Request, Response } from "express";
import bcrypt from "bcryptjs";
import { pool } from "../config/database.js";
import { RegisterSchema, LoginSchema } from "../models/user.js";
import { validate } from "../middleware/validate.js";
import { generateToken } from "../middleware/auth.js";

const router = Router();

router.post(
  "/register",
  validate(RegisterSchema),
  async (req: Request, res: Response): Promise<void> => {
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
  },
);

router.post(
  "/login",
  validate(LoginSchema),
  async (req: Request, res: Response): Promise<void> => {
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
  },
);

export default router;
