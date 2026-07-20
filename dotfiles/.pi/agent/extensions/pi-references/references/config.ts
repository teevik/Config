export interface LocalReferenceSpec {
  kind: "local";
  alias: string;
  path: string;
  description?: string;
  hidden: boolean;
}

export interface GitReferenceSpec {
  kind: "git";
  alias: string;
  repository: string;
  branch?: string;
  description?: string;
  hidden: boolean;
}

export type ReferenceSpec = LocalReferenceSpec | GitReferenceSpec;

export interface ParseResult {
  references: ReferenceSpec[];
  errors: string[];
}

const INVALID_ALIAS = /[/\s`,]/;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function looksLikeLocalPath(value: string): boolean {
  return value.startsWith(".") || value.startsWith("/") || value.startsWith("~");
}

function parseEntry(alias: string, entry: unknown): ReferenceSpec | string {
  if (typeof entry === "string") {
    if (entry.length === 0) return `reference "${alias}": shorthand value must not be empty`;
    return looksLikeLocalPath(entry)
      ? { kind: "local", alias, path: entry, hidden: false }
      : { kind: "git", alias, repository: entry, hidden: false };
  }

  if (!isRecord(entry)) {
    return `reference "${alias}": expected a string or an object, got ${typeof entry}`;
  }

  const { path, repository, branch, description, hidden } = entry;
  if (path !== undefined && typeof path !== "string") {
    return `reference "${alias}": "path" must be a string`;
  }
  if (repository !== undefined && typeof repository !== "string") {
    return `reference "${alias}": "repository" must be a string`;
  }
  if (branch !== undefined && typeof branch !== "string") {
    return `reference "${alias}": "branch" must be a string`;
  }
  if (description !== undefined && typeof description !== "string") {
    return `reference "${alias}": "description" must be a string`;
  }
  if (hidden !== undefined && typeof hidden !== "boolean") {
    return `reference "${alias}": "hidden" must be a boolean`;
  }

  if (path !== undefined && repository !== undefined) {
    return `reference "${alias}": "path" and "repository" are mutually exclusive`;
  }
  if (path === undefined && repository === undefined) {
    return `reference "${alias}": needs either "path" or "repository"`;
  }
  if (path !== undefined && branch !== undefined) {
    return `reference "${alias}": "branch" only applies to repository references`;
  }

  if (path !== undefined) {
    return { kind: "local", alias, path, description, hidden: hidden ?? false };
  }
  return {
    kind: "git",
    alias,
    repository: repository as string,
    branch,
    description,
    hidden: hidden ?? false,
  };
}

export function parseReferencesConfig(raw: unknown): ParseResult {
  const references: ReferenceSpec[] = [];
  const errors: string[] = [];

  if (!isRecord(raw)) {
    return { references, errors: ["config must be a JSON object"] };
  }
  if (!isRecord(raw.references)) {
    return { references, errors: ['config must have a "references" object'] };
  }

  for (const [alias, entry] of Object.entries(raw.references)) {
    if (alias.length === 0 || INVALID_ALIAS.test(alias)) {
      errors.push(
        `reference "${alias}": alias must not be empty or contain "/", whitespace, backticks, or commas`,
      );
      continue;
    }
    const parsed = parseEntry(alias, entry);
    if (typeof parsed === "string") {
      errors.push(parsed);
    } else {
      references.push(parsed);
    }
  }

  return { references, errors };
}

export function mergeReferences(
  global: ReferenceSpec[],
  project: ReferenceSpec[],
): ReferenceSpec[] {
  const byAlias = new Map<string, ReferenceSpec>();
  for (const ref of global) byAlias.set(ref.alias, ref);
  for (const ref of project) byAlias.set(ref.alias, ref);
  return [...byAlias.values()];
}
