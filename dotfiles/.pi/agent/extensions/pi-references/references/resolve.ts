import * as path from "node:path";

export interface GitRemote {
  url: string;
  host: string;
  repoPath: string;
}

export function resolveLocalPath(value: string, configDir: string, homeDir: string): string {
  if (value === "~" || value.startsWith("~/")) {
    return path.normalize(path.join(homeDir, value.slice(1)));
  }
  if (path.isAbsolute(value)) {
    return path.normalize(value);
  }
  return path.normalize(path.join(configDir, value));
}

function stripGitSuffix(value: string): string {
  return value.endsWith(".git") ? value.slice(0, -4) : value;
}

function trimSlashes(value: string): string {
  return value.replace(/^\/+|\/+$/g, "");
}

export function parseRepository(repository: string): GitRemote | undefined {
  if (repository.length === 0) return undefined;

  if (/^(https?|ssh|git):\/\//.test(repository)) {
    let parsed: URL;
    try {
      parsed = new URL(repository);
    } catch {
      return undefined;
    }
    const repoPath = stripGitSuffix(trimSlashes(parsed.pathname));
    if (parsed.hostname.length === 0 || repoPath.length === 0) return undefined;
    return { url: repository, host: parsed.hostname, repoPath };
  }

  const scpMatch = /^[\w.-]+@([\w.-]+):(.+)$/.exec(repository);
  if (scpMatch) {
    return {
      url: repository,
      host: scpMatch[1],
      repoPath: stripGitSuffix(trimSlashes(scpMatch[2])),
    };
  }

  const segments = repository.split("/").filter((s) => s.length > 0);
  if (segments.length < 2 || repository.startsWith("/")) return undefined;

  if (segments[0].includes(".")) {
    const host = segments[0];
    const repoPath = stripGitSuffix(segments.slice(1).join("/"));
    if (repoPath.length === 0) return undefined;
    return { url: `https://${host}/${repoPath}.git`, host, repoPath };
  }

  if (segments.length === 2) {
    const repoPath = stripGitSuffix(segments.join("/"));
    return { url: `https://github.com/${repoPath}.git`, host: "github.com", repoPath };
  }

  return undefined;
}

function sanitizeSegment(value: string): string {
  const cleaned = value
    .replace(/[^\w.-]/g, "-")
    .replace(/\.{2,}/g, "-")
    .replace(/^\.+/, "-");
  return cleaned.length > 0 ? cleaned : "-";
}

export function gitCacheDir(
  remote: GitRemote,
  branch: string | undefined,
  cacheRoot: string,
): string {
  const repoSegments = remote.repoPath.split("/").map(sanitizeSegment);
  const branchSegment = branch === undefined ? "_default" : sanitizeSegment(branch);
  return path.join(cacheRoot, sanitizeSegment(remote.host), ...repoSegments, branchSegment);
}
