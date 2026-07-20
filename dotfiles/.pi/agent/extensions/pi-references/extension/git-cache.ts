import { execFile } from "node:child_process";
import * as fs from "node:fs";
import * as path from "node:path";
import { promisify } from "node:util";

const run = promisify(execFile);

export interface CloneTarget {
  url: string;
  branch: string | undefined;
  dir: string;
}

export type EnsureCloneResult = "cloned" | "exists";

export async function ensureClone(target: CloneTarget): Promise<EnsureCloneResult> {
  if (fs.existsSync(path.join(target.dir, ".git"))) {
    return "exists";
  }

  fs.mkdirSync(path.dirname(target.dir), { recursive: true });
  const branchArgs = target.branch === undefined ? [] : ["--branch", target.branch];
  await run("git", [
    "clone",
    "--depth",
    "1",
    "--single-branch",
    ...branchArgs,
    "--",
    target.url,
    target.dir,
  ]);
  return "cloned";
}

export async function updateClone(dir: string): Promise<void> {
  await run("git", ["fetch", "origin"], { cwd: dir });
  await run("git", ["reset", "--hard", "FETCH_HEAD"], { cwd: dir });
}
