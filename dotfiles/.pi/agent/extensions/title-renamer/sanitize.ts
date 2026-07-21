export interface SanitizeOptions {
  maxChars: number;
}

export interface SanitizedTitle {
  ok: boolean;
  title?: string;
  reason?: string;
}

const ANSI_ESCAPE_PATTERN =
  /\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~]|\][^\x07]*(?:\x07|\x1B\\))/g;
const CONTROL_PATTERN = /[\x00-\x08\x0B\x0C\x0E-\x1F\x7F\u0080-\u009F]/g;
const MARKDOWN_LINK_PATTERN = /\[([^\]]+)]\(([^)]+)\)/g;

function stripWrapping(value: string): string {
  let output = value.trim();
  const pairs: Array<[string, string]> = [
    ["```", "```"],
    ["`", "`"],
    ['"', '"'],
    ["'", "'"],
    ["“", "”"],
    ["‘", "’"],
    ["**", "**"],
    ["__", "__"],
    ["*", "*"],
    ["_", "_"],
    ["~~", "~~"],
  ];

  let changed = true;
  while (changed) {
    changed = false;
    for (const [start, end] of pairs) {
      if (
        output.startsWith(start) &&
        output.endsWith(end) &&
        output.length >= start.length + end.length
      ) {
        output = output.slice(start.length, output.length - end.length).trim();
        changed = true;
      }
    }
  }

  return output.replace(/^[`"'“”‘’*_~\s]+|[`"'“”‘’*_~\s]+$/g, "").trim();
}

function cleanCandidate(candidate: string): string {
  let output = candidate
    .replace(ANSI_ESCAPE_PATTERN, "")
    .replace(CONTROL_PATTERN, "")
    .trim();
  if (!output || /^```[a-zA-Z0-9_-]*$/.test(output)) {
    return "";
  }

  output = output.replace(MARKDOWN_LINK_PATTERN, "$1");
  output = output.replace(/^#{1,6}\s+/, "");
  output = output.replace(/^[-*+]\s+/, "");
  output = output.replace(/^\d+[.)]\s+/, "");
  output = output.replace(/^>\s+/, "");
  output = stripWrapping(output);
  output = output.replace(/[`"'“”‘’]/g, "");
  output = output.replace(/[\r\n]+/g, " ");
  output = output.replace(/\s+/g, " ").trim();
  return stripWrapping(output);
}

function truncateTitle(title: string, maxChars: number): string {
  const chars = Array.from(title);
  if (chars.length <= maxChars) {
    return title;
  }
  return chars.slice(0, maxChars).join("").trim();
}

export function sanitizeTitle(
  input: unknown,
  options: SanitizeOptions,
): SanitizedTitle {
  if (typeof input !== "string") {
    return { ok: false, reason: "Title is not a string." };
  }
  if (!Number.isInteger(options.maxChars) || options.maxChars <= 0) {
    return { ok: false, reason: "maxChars must be a positive integer." };
  }

  const normalized = input
    .replace(ANSI_ESCAPE_PATTERN, "")
    .replace(CONTROL_PATTERN, "");
  const candidates = normalized.split(/[\r\n]+/);
  for (const candidate of candidates) {
    const cleaned = truncateTitle(cleanCandidate(candidate), options.maxChars);
    if (cleaned) {
      return { ok: true, title: cleaned };
    }
  }

  const cleaned = truncateTitle(cleanCandidate(normalized), options.maxChars);
  if (cleaned) {
    return { ok: true, title: cleaned };
  }

  return { ok: false, reason: "Title is empty after sanitization." };
}
