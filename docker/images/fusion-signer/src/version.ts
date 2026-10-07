/**
 * The service version, read once at load from package.json.
 *
 * The path is relative to this module, so it resolves to the package root
 * both from src/ (tests) and from dist/ (the Docker image copies
 * package.json next to dist/).
 */
import { readFileSync } from "node:fs";

/** Parsed package.json; only `version` is used. */
const pkg = JSON.parse(
  readFileSync(new URL("../package.json", import.meta.url), "utf8"),
) as { version: string };

/** Reported by `GET /status` so callers can see which build is running. */
export const VERSION = pkg.version;
