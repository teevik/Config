import path from "node:path";
import type { ExtensionContext } from "@earendil-works/pi-coding-agent";
import type { TitleRenamerConfig } from "./config.ts";
import { getLatestResetIndex } from "./state.ts";

export interface NamingContext {
  projectName?: string;
  cwd?: string;
  model?: string;
  firstUserMessage?: string;
  firstAssistantMessage?: string;
}

type ContentBlock = {
  type?: string;
  text?: string;
};

type MessageEntry = {
  type: string;
  message?: {
    role?: string;
    content?: unknown;
  };
};

export interface NamingContextOptions {
  afterLatestReset?: boolean;
  firstUserMessage?: string;
}

const MAX_MESSAGE_CHARS = 2000;

function extractText(content: unknown): string {
  if (typeof content === "string") {
    return content.trim();
  }
  if (!Array.isArray(content)) {
    return "";
  }

  return content
    .flatMap((part): string[] => {
      if (!part || typeof part !== "object") {
        return [];
      }
      const block = part as ContentBlock;
      return block.type === "text" && typeof block.text === "string"
        ? [block.text]
        : [];
    })
    .join("\n")
    .trim();
}

function truncateForPrompt(value: string): string {
  const text = value.trim();
  if (text.length <= MAX_MESSAGE_CHARS) {
    return text;
  }
  return `${text.slice(0, MAX_MESSAGE_CHARS)}...`;
}

function getStartIndex(
  branch: readonly MessageEntry[],
  options: NamingContextOptions | undefined,
): number {
  return options?.afterLatestReset
    ? getLatestResetIndex(branch as Parameters<typeof getLatestResetIndex>[0]) +
        1
    : 0;
}

export function findFirstTurn(
  branch: readonly MessageEntry[],
  options?: NamingContextOptions,
): { firstUserMessage?: string; firstAssistantMessage?: string } {
  let firstUserMessage: string | undefined;
  let firstAssistantMessage: string | undefined;
  const startIndex = getStartIndex(branch, options);

  for (const entry of branch.slice(startIndex)) {
    if (entry.type !== "message" || !entry.message?.role) {
      continue;
    }

    const text = extractText(entry.message.content);
    if (!text) {
      continue;
    }

    if (!firstUserMessage && entry.message.role === "user") {
      firstUserMessage = truncateForPrompt(text);
      continue;
    }
    if (
      firstUserMessage &&
      !firstAssistantMessage &&
      entry.message.role === "assistant"
    ) {
      firstAssistantMessage = truncateForPrompt(text);
      break;
    }
  }

  return { firstUserMessage, firstAssistantMessage };
}

export function hasFirstUserMessage(
  ctx: Pick<ExtensionContext, "sessionManager">,
  options?: NamingContextOptions,
): boolean {
  return !!findFirstTurn(
    ctx.sessionManager.getBranch() as MessageEntry[],
    options,
  ).firstUserMessage;
}

export function hasFirstTurn(
  ctx: Pick<ExtensionContext, "sessionManager">,
  options?: NamingContextOptions,
): boolean {
  const firstTurn = findFirstTurn(
    ctx.sessionManager.getBranch() as MessageEntry[],
    options,
  );
  return !!firstTurn.firstUserMessage && !!firstTurn.firstAssistantMessage;
}

export function collectNamingContext(
  ctx: Pick<ExtensionContext, "cwd" | "model" | "sessionManager">,
  config: TitleRenamerConfig,
  options?: NamingContextOptions,
): NamingContext {
  const firstTurn = findFirstTurn(
    ctx.sessionManager.getBranch() as MessageEntry[],
    options,
  );
  const namingContext: NamingContext = {};

  if (config.style.includeProject) {
    namingContext.projectName = path.basename(ctx.cwd);
  }
  if (config.input.includeCwd) {
    namingContext.cwd = ctx.cwd;
  }
  if (config.input.includeModel && ctx.model) {
    namingContext.model = `${ctx.model.provider}/${ctx.model.id}`;
  }
  if (config.input.includeFirstUserMessage) {
    const firstUserMessage =
      options?.firstUserMessage ?? firstTurn.firstUserMessage;
    namingContext.firstUserMessage = firstUserMessage
      ? truncateForPrompt(firstUserMessage)
      : undefined;
  }
  if (config.input.includeFirstAssistantMessage) {
    namingContext.firstAssistantMessage = firstTurn.firstAssistantMessage;
  }

  return namingContext;
}
