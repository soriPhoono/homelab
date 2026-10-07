import {
  existsSync,
  mkdirSync,
  readFileSync,
  renameSync,
  writeFileSync,
} from "node:fs";
import { join } from "node:path";

export interface StoredResult {
  bodyHash: string;
  status: number;
  body: unknown;
}

interface State {
  requests: Record<string, StoredResult>;
  dailyUsd: Record<string, number>;
  lastOrderAt: Record<string, number>;
}

export class Store {
  private readonly file: string;
  private readonly haltFile: string;
  private state: State;

  constructor(
    dir: string,
    private readonly now: () => number = Date.now,
  ) {
    mkdirSync(dir, { recursive: true });
    this.file = join(dir, "state.json");
    this.haltFile = join(dir, "halt");
    this.state = existsSync(this.file)
      ? (JSON.parse(readFileSync(this.file, "utf8")) as State)
      : { requests: {}, dailyUsd: {}, lastOrderAt: {} };
  }

  private save(): void {
    const tmp = `${this.file}.tmp`;
    writeFileSync(tmp, JSON.stringify(this.state));
    renameSync(tmp, this.file);
  }

  private today(): string {
    return new Date(this.now()).toISOString().slice(0, 10);
  }

  isHalted(): boolean {
    return existsSync(this.haltFile);
  }

  halt(reason: string): void {
    const at = new Date(this.now()).toISOString();
    writeFileSync(this.haltFile, JSON.stringify({ at, reason }) + "\n");
  }

  getRequest(id: string): StoredResult | undefined {
    return this.state.requests[id];
  }

  putRequest(id: string, result: StoredResult): void {
    this.state.requests[id] = result;
    this.save();
  }

  dailyUsd(): number {
    return this.state.dailyUsd[this.today()] ?? 0;
  }

  addDailyUsd(usd: number): void {
    const day = this.today();
    this.state.dailyUsd[day] = (this.state.dailyUsd[day] ?? 0) + usd;
    this.save();
  }

  lastOrderAt(key: string): number | undefined {
    return this.state.lastOrderAt[key];
  }

  setLastOrderAt(key: string, ms: number): void {
    this.state.lastOrderAt[key] = ms;
    this.save();
  }
}
