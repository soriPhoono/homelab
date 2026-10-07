/**
 * Persistent state in the data directory (a Docker volume at /data).
 *
 * Two files live there:
 * - `state.json`: the request log (for idempotency), the USD submitted per
 *   UTC day (daily cap) and the last order time per asset (spacing).
 * - `halt`: present means "stop trading". Only `POST /halt` creates it, and
 *   nothing in the service removes it; the user deletes it on the VPS.
 *
 * All writes are synchronous and durable (temp file, fsync, rename, fsync of
 * the directory), so a crash never leaves a half-written state file.
 */
import {
  closeSync,
  existsSync,
  fsyncSync,
  mkdirSync,
  openSync,
  readFileSync,
  renameSync,
  writeFileSync,
} from "node:fs";
import { join } from "node:path";

/**
 * The outcome stored under a requestId. A retry with the same id and the
 * same body gets exactly this back instead of running again.
 */
export interface StoredResult {
  /** sha256 of the request body; a different body with the same id is a 409. */
  bodyHash: string;
  /** HTTP status that was (or will be) returned. */
  status: number;
  /** Response body that was (or will be) returned. */
  body: unknown;
}

/** Shape of state.json. */
interface State {
  /**
   * requestId -> stored outcome (also holds the "submitting" and "sending"
   * intent markers).
   */
  requests: Record<string, StoredResult>;
  /** UTC date (YYYY-MM-DD) -> USD of orders submitted that day. */
  dailyUsd: Record<string, number>;
  /** Asset -> epoch ms of its last submitted order. */
  lastOrderAt: Record<string, number>;
}

/**
 * File-backed store used by Service. One instance per process; the service
 * serializes order and withdrawal work, so there is no concurrent writer.
 */
export class Store {
  private readonly dir: string;
  private readonly file: string;
  private readonly haltFile: string;
  /** In-memory copy of state.json; every mutation is saved immediately. */
  private state: State;

  /**
   * Opens (or creates) the store in `dir`. `now` is injectable so tests can
   * control the UTC day boundary.
   */
  constructor(
    dir: string,
    private readonly now: () => number = Date.now,
  ) {
    mkdirSync(dir, { recursive: true });
    this.dir = dir;
    this.file = join(dir, "state.json");
    this.haltFile = join(dir, "halt");
    this.state = existsSync(this.file)
      ? (JSON.parse(readFileSync(this.file, "utf8")) as State)
      : { requests: {}, dailyUsd: {}, lastOrderAt: {} };
  }

  /**
   * Write state.json atomically and durably: write a 0600 temp file, fsync
   * it, rename it over the old file, then fsync the directory.
   */
  private save(): void {
    const tmp = `${this.file}.tmp`;
    const fd = openSync(tmp, "w", 0o600);
    try {
      writeFileSync(fd, JSON.stringify(this.state));
      fsyncSync(fd);
    } finally {
      closeSync(fd);
    }
    renameSync(tmp, this.file);
    this.syncDir();
  }

  /** Makes the rename durable; some platforms cannot fsync a directory. */
  private syncDir(): void {
    let fd: number | undefined;
    try {
      fd = openSync(this.dir, "r");
      fsyncSync(fd);
    } catch (err) {
      const code = (err as NodeJS.ErrnoException).code;
      if (code !== "EISDIR" && code !== "EINVAL") throw err;
    } finally {
      if (fd !== undefined) closeSync(fd);
    }
  }

  /** Current UTC date as YYYY-MM-DD; the key for the daily total. */
  private today(): string {
    return new Date(this.now()).toISOString().slice(0, 10);
  }

  /**
   * True while the halt file exists. Read from disk on every call, so
   * deleting the file resumes trading without a restart.
   */
  isHalted(): boolean {
    return existsSync(this.haltFile);
  }

  /** Create the halt file with a timestamp and reason (`POST /halt`). */
  halt(reason: string): void {
    const at = new Date(this.now()).toISOString();
    writeFileSync(this.haltFile, JSON.stringify({ at, reason }) + "\n");
  }

  /** Stored outcome for `id`, or undefined if this requestId is new. */
  getRequest(id: string): StoredResult | undefined {
    return this.state.requests[id];
  }

  /** Store (or overwrite) the outcome for `id` and save immediately. */
  putRequest(id: string, result: StoredResult): void {
    this.state.requests[id] = result;
    this.save();
  }

  /** USD submitted so far today (UTC). Resets automatically at midnight. */
  dailyUsd(): number {
    return this.state.dailyUsd[this.today()] ?? 0;
  }

  /** Add `usd` to today's total. Called just before an order is submitted. */
  addDailyUsd(usd: number): void {
    const day = this.today();
    this.state.dailyUsd[day] = (this.state.dailyUsd[day] ?? 0) + usd;
    this.save();
  }

  /** Epoch ms of the last submitted order for `key` (an asset), if any. */
  lastOrderAt(key: string): number | undefined {
    return this.state.lastOrderAt[key];
  }

  /** Record that an order for `key` was submitted at `ms`. */
  setLastOrderAt(key: string, ms: number): void {
    this.state.lastOrderAt[key] = ms;
    this.save();
  }
}
