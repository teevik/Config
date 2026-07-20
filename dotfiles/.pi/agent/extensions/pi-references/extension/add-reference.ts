import * as fs from "node:fs";
import * as path from "node:path";
import { parseReferencesConfig } from "../references/config.ts";

export interface AddReferenceInput {
  alias: string;
  target: string;
  scope: "project" | "global";
  branch?: string;
  description?: string;
  hidden?: boolean;
}

export interface AddReferenceOptions extends AddReferenceInput {
  cwd: string;
  homeDir: string;
}

export interface AddReferenceResult {
  file: string;
  kind: "local" | "git";
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function looksLikeLocalPath(value: string): boolean {
  return value.startsWith(".") || value.startsWith("/") || value.startsWith("~");
}

function configFileFor(scope: "project" | "global", cwd: string, homeDir: string): string {
  return scope === "project"
    ? path.join(cwd, ".pi", "references.json")
    : path.join(homeDir, ".pi", "agent", "references.json");
}

function readConfig(file: string): Record<string, unknown> {
  if (!fs.existsSync(file)) return { references: {} };
  const raw = JSON.parse(fs.readFileSync(file, "utf8")) as unknown;
  if (!isRecord(raw)) throw new Error(`${file}: config must be a JSON object`);
  return raw;
}

export function addReferenceToConfig(options: AddReferenceOptions): AddReferenceResult {
  const kind = looksLikeLocalPath(options.target) ? "local" : "git";
  const entry: Record<string, unknown> =
    kind === "local" ? { path: options.target } : { repository: options.target };
  if (options.branch !== undefined) entry.branch = options.branch;
  if (options.description !== undefined) entry.description = options.description;
  if (options.hidden === true) entry.hidden = true;

  const validation = parseReferencesConfig({ references: { [options.alias]: entry } });
  if (validation.errors.length > 0) throw new Error(validation.errors.join("; "));

  const file = configFileFor(options.scope, options.cwd, options.homeDir);
  const config = readConfig(file);
  const references = isRecord(config.references) ? { ...config.references } : {};
  references[options.alias] = entry;
  config.references = references;

  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, `${JSON.stringify(config, null, 2)}\n`);
  return { file, kind };
}

function tokenize(input: string): string[] | undefined {
  const tokens: string[] = [];
  let current = "";
  let quote: '"' | "'" | undefined;
  let escaping = false;

  for (const char of input) {
    if (escaping) {
      current += char;
      escaping = false;
      continue;
    }
    if (char === "\\") {
      escaping = true;
      continue;
    }
    if (quote !== undefined) {
      if (char === quote) quote = undefined;
      else current += char;
      continue;
    }
    if (char === '"' || char === "'") {
      quote = char;
      continue;
    }
    if (/\s/.test(char)) {
      if (current.length > 0) {
        tokens.push(current);
        current = "";
      }
      continue;
    }
    current += char;
  }

  if (escaping) current += "\\";
  if (quote !== undefined) return undefined;
  if (current.length > 0) tokens.push(current);
  return tokens;
}

export function parseAddReferenceArgs(args: string): AddReferenceInput | string {
  const tokens = tokenize(args);
  if (tokens === undefined) return "unterminated quote in arguments";

  let scope: "project" | "global" = "project";
  let branch: string | undefined;
  let description: string | undefined;
  let hidden = false;
  const positional: string[] = [];

  for (let index = 0; index < tokens.length; index += 1) {
    const token = tokens[index];
    if (token === "--global") {
      scope = "global";
    } else if (token === "--project") {
      scope = "project";
    } else if (token === "--hidden") {
      hidden = true;
    } else if (token === "--branch") {
      const value = tokens[index + 1];
      if (value === undefined) return "--branch needs a value";
      branch = value;
      index += 1;
    } else if (token === "--description" || token === "--desc") {
      const value = tokens[index + 1];
      if (value === undefined) return `${token} needs a value`;
      description = value;
      index += 1;
    } else if (token.startsWith("--")) {
      return `unknown option ${token}`;
    } else {
      positional.push(token);
    }
  }

  if (positional.length !== 2) {
    return "usage: /references add <alias> <path-or-repository> [--global] [--branch <ref>] [--description <text>]";
  }

  return {
    alias: positional[0] as string,
    target: positional[1] as string,
    scope,
    branch,
    description,
    hidden,
  };
}
