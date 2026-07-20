import { readFile } from "node:fs/promises";
import { dirname } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
  type AutocompleteItem,
  type AutocompleteProvider,
  fuzzyFilter,
} from "@earendil-works/pi-tui";

const MAX_SUGGESTIONS = 30;
const SKILL_COMMAND_PREFIX = "skill:";

type SkillCommand = {
  name: string;
  description?: string;
  path: string;
};

function getSkills(pi: ExtensionAPI): SkillCommand[] {
  return pi
    .getCommands()
    .filter((command) => command.source === "skill")
    .map((command) => ({
      name: command.name.startsWith(SKILL_COMMAND_PREFIX)
        ? command.name.slice(SKILL_COMMAND_PREFIX.length)
        : command.name,
      description: command.description,
      path: command.sourceInfo.path,
    }));
}

function extractSkillToken(textBeforeCursor: string): string | undefined {
  const match = textBeforeCursor.match(/(?:^|[\t ])\$([^\s$]*)$/);
  return match?.[1];
}

function skillItems(skills: SkillCommand[], query: string): AutocompleteItem[] {
  const matches = query
    ? fuzzyFilter(skills, query, (skill) => skill.name)
    : [...skills].sort((left, right) => left.name.localeCompare(right.name));

  return matches.slice(0, MAX_SUGGESTIONS).map((skill) => ({
    value: `$${skill.name}`,
    label: `$${skill.name}`,
    description: skill.description,
  }));
}

function createSkillAutocompleteProvider(
  current: AutocompleteProvider,
  pi: ExtensionAPI,
): AutocompleteProvider {
  return {
    triggerCharacters: [
      ...new Set([...(current.triggerCharacters ?? []), "$"]),
    ],

    async getSuggestions(lines, cursorLine, cursorCol, options) {
      const currentLine = lines[cursorLine] ?? "";
      const textBeforeCursor = currentLine.slice(0, cursorCol);
      const query = extractSkillToken(textBeforeCursor);
      if (query === undefined) {
        return current.getSuggestions(lines, cursorLine, cursorCol, options);
      }

      const items = skillItems(getSkills(pi), query);
      if (options.signal.aborted || items.length === 0) {
        return current.getSuggestions(lines, cursorLine, cursorCol, options);
      }

      return {
        items,
        prefix: `$${query}`,
      };
    },

    applyCompletion(lines, cursorLine, cursorCol, item, prefix) {
      const skillValues = new Set(
        getSkills(pi).map((skill) => `$${skill.name}`),
      );
      if (!prefix.startsWith("$") || !skillValues.has(item.value)) {
        return current.applyCompletion(
          lines,
          cursorLine,
          cursorCol,
          item,
          prefix,
        );
      }

      const currentLine = lines[cursorLine] ?? "";
      const beforePrefix = currentLine.slice(0, cursorCol - prefix.length);
      const afterCursor = currentLine.slice(cursorCol);
      const separator =
        afterCursor.length === 0 || /^[A-Za-z0-9_$-]/.test(afterCursor)
          ? " "
          : "";
      const newLines = [...lines];
      newLines[cursorLine] =
        `${beforePrefix}${item.value}${separator}${afterCursor}`;

      return {
        lines: newLines,
        cursorLine,
        cursorCol: beforePrefix.length + item.value.length + separator.length,
      };
    },

    shouldTriggerFileCompletion(lines, cursorLine, cursorCol) {
      return (
        current.shouldTriggerFileCompletion?.(lines, cursorLine, cursorCol) ??
        true
      );
    },
  };
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function findMentionedSkills(
  text: string,
  skills: SkillCommand[],
): SkillCommand[] {
  if (skills.length === 0) return [];

  const byName = new Map(skills.map((skill) => [skill.name, skill]));
  const names = [...byName.keys()].sort(
    (left, right) => right.length - left.length,
  );
  const mentionPattern = new RegExp(
    `(?:^|[\\t \\n])\\$(${names.map(escapeRegExp).join("|")})(?![A-Za-z0-9_-])`,
    "g",
  );
  const mentioned: SkillCommand[] = [];
  const seen = new Set<string>();

  for (const match of text.matchAll(mentionPattern)) {
    const name = match[1];
    if (!name || seen.has(name)) continue;
    const skill = byName.get(name);
    if (!skill) continue;
    seen.add(name);
    mentioned.push(skill);
  }

  return mentioned;
}

function stripFrontmatter(content: string): string {
  const normalized = content.replace(/\r\n/g, "\n").replace(/\r/g, "\n");
  if (!normalized.startsWith("---")) return normalized;

  const endIndex = normalized.indexOf("\n---", 3);
  return endIndex === -1 ? normalized : normalized.slice(endIndex + 4).trim();
}

async function expandSkill(skill: SkillCommand): Promise<string> {
  const content = await readFile(skill.path, "utf8");
  const body = stripFrontmatter(content).trim();
  return `<skill name="${skill.name}" location="${skill.path}">\nReferences are relative to ${dirname(skill.path)}.\n\n${body}\n</skill>`;
}

export default function skillAutocomplete(pi: ExtensionAPI): void {
  pi.on("session_start", (_event, ctx) => {
    if (ctx.mode !== "tui") return;
    ctx.ui.addAutocompleteProvider((current) =>
      createSkillAutocompleteProvider(current, pi),
    );
  });

  pi.on("input", async (event, ctx) => {
    if (event.text.startsWith("/")) return { action: "continue" };

    const mentioned = findMentionedSkills(event.text, getSkills(pi));
    if (mentioned.length === 0) return { action: "continue" };

    const [firstSkill, ...additionalSkills] = mentioned;
    if (!firstSkill) return { action: "continue" };

    try {
      const additionalBlocks = await Promise.all(
        additionalSkills.map(expandSkill),
      );
      const prompt =
        additionalBlocks.length === 0
          ? event.text
          : `${additionalBlocks.join("\n\n")}\n\n${event.text}`;
      return {
        action: "transform",
        text: `/skill:${firstSkill.name} ${prompt}`,
      };
    } catch (error) {
      const details = error instanceof Error ? error.message : String(error);
      ctx.ui.notify(`Could not load mentioned skill: ${details}`, "error");
      return { action: "continue" };
    }
  });
}
