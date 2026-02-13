import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import { config } from "./config/index.js";
import { initDatabase } from "./config/database.js";
import authRoutes from "./routes/auth.js";
import fragmentRoutes from "./routes/fragments.js";

const app = express();

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan("dev"));
app.use(express.json({ limit: "10mb" }));

// Health check
app.get("/health", (_req, res) => {
  res.json({ status: "ok", version: "0.1.0" });
});

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/fragments", fragmentRoutes);

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
