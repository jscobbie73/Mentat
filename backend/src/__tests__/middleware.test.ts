import { describe, it, expect, vi } from "vitest";
import { Request, Response, NextFunction } from "express";
import { asyncHandler } from "../middleware/asyncHandler.js";

describe("asyncHandler", () => {
  it("calls the handler function", async () => {
    const handler = vi.fn(async (_req: Request, res: Response) => {
      res.json({ ok: true });
    });

    const wrapped = asyncHandler(handler);
    const req = {} as Request;
    const res = { json: vi.fn() } as unknown as Response;
    const next = vi.fn() as NextFunction;

    await wrapped(req, res, next);

    expect(handler).toHaveBeenCalledWith(req, res, next);
    expect(next).not.toHaveBeenCalled();
  });

  it("forwards rejected promises to next()", async () => {
    const error = new Error("Something went wrong");
    const handler = vi.fn(async () => {
      throw error;
    });

    const wrapped = asyncHandler(handler);
    const req = {} as Request;
    const res = {} as Response;
    const next = vi.fn() as NextFunction;

    await wrapped(req, res, next);

    expect(next).toHaveBeenCalledWith(error);
  });
});
