import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import rateLimit from "express-rate-limit";
import { config } from "./config/index.js";
import { initDatabase } from "./config/database.js";
import authRoutes from "./routes/auth.js";
import fragmentRoutes from "./routes/fragments.js";
import collectionRoutes from "./routes/collections.js";
import insightRoutes from "./routes/insights.js";

const app = express();

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan("dev"));
app.use(express.json({ limit: "10mb" }));

// Rate limiting on auth routes (prevent brute-force)
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20, // 20 attempts per window
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many requests, please try again later" },
});

// Health check
app.get("/health", (_req, res) => {
  res.json({ status: "ok", version: "0.1.0" });
});

// Routes
app.use("/api/auth", authLimiter, authRoutes);
app.use("/api/fragments", fragmentRoutes);
app.use("/api/collections", collectionRoutes);
app.use("/api/insights", insightRoutes);

// Global error handler
app.use(
  (
    err: Error,
    _req: express.Request,
    res: express.Response,
    _next: express.NextFunction,
  ) => {
    console.error("Unhandled error:", err);
    res.status(500).json({ error: "Internal server error" });
  },
);

// Start server
async function start() {
  await initDatabase();
  app.listen(config.PORT, () => {
    console.log(
      `Mentat API running on port ${config.PORT} [${config.NODE_ENV}]`,
    );
  });
}

start().catch((err) => {
  console.error("Failed to start server:", err);
  process.exit(1);
});

export default app;
