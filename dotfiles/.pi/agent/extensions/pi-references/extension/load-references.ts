import * as fs from "node:fs";
import * as path from "node:path";
import { mergeReferences, parseReferencesConfig } from "../references/config.ts";
import type { ReferenceSpec } from "../references/config.ts";
import type { ResolvedReference } from "../references/context.ts";
import { gitCacheDir, parseRepository, resolveLocalPath } from "../references/resolve.ts";

export interface LoadedReference extends ResolvedReference {
  git?: { url: string; branch: string | undefined };
}

export interface LoadResult {
  references: LoadedReference[];
  errors: string[];
}

export interface LoadOptions {
  cwd: string;
  homeDir: string;
  projectTrusted: boolean;
}

interface SourcedSpec {
  spec: ReferenceSpec;
  configDir: string;
}

function readSpecs(file: string, errors: string[]): ReferenceSpec[] {
  if (!fs.existsSync(file)) return [];

  let raw: unknown;
  try {
    raw = JSON.parse(fs.readFileSync(file, "utf8"));
  } catch (error) {
    errors.push(`${file}: ${error instanceof Error ? error.message : String(error)}`);
    return [];
  }

  const parsed = parseReferencesConfig(raw);
  errors.push(...parsed.errors.map((message) => `${file}: ${message}`));
  return parsed.references;
}

function resolveSpec(
  { spec, configDir }: SourcedSpec,
  homeDir: string,
  cacheRoot: string,
  errors: string[],
): LoadedReference | undefined {
  if (spec.kind === "local") {
    return {
      alias: spec.alias,
      kind: "local",
      dir: resolveLocalPath(spec.path, configDir, homeDir),
      description: spec.description,
      hidden: spec.hidden,
      state: "ready",
    };
  }

  const remote = parseRepository(spec.repository);
  if (remote === undefined) {
    errors.push(`reference "${spec.alias}": cannot parse repository "${spec.repository}"`);
    return undefined;
  }

  const dir = gitCacheDir(remote, spec.branch, cacheRoot);
  return {
    alias: spec.alias,
    kind: "git",
    dir,
    description: spec.description,
    hidden: spec.hidden,
    state: fs.existsSync(path.join(dir, ".git")) ? "ready" : "pending",
    git: { url: remote.url, branch: spec.branch },
  };
}

export function loadReferences(options: LoadOptions): LoadResult {
  const errors: string[] = [];
  const globalConfigDir = path.join(options.homeDir, ".pi", "agent");
  const projectConfigDir = path.join(options.cwd, ".pi");
  const cacheRoot = path.join(globalConfigDir, "references");

  const globalSpecs = readSpecs(path.join(globalConfigDir, "references.json"), errors);
  const projectSpecs = options.projectTrusted
    ? readSpecs(path.join(projectConfigDir, "references.json"), errors)
    : [];

  const sources = new Map<string, string>();
  for (const spec of globalSpecs) sources.set(spec.alias, globalConfigDir);
  for (const spec of projectSpecs) sources.set(spec.alias, projectConfigDir);

  const merged = mergeReferences(globalSpecs, projectSpecs);
  const references: LoadedReference[] = [];
  for (const spec of merged) {
    const configDir = sources.get(spec.alias) ?? projectConfigDir;
    const resolved = resolveSpec({ spec, configDir }, options.homeDir, cacheRoot, errors);
    if (resolved !== undefined) references.push(resolved);
  }

  return { references, errors };
}
