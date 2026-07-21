import path from "node:path";
import type { Model } from "@earendil-works/pi-ai";
import type { ExtensionContext } from "@earendil-works/pi-coding-agent";
import type { TitleRenamerConfig } from "./config.ts";
import type { NamingContext } from "./context.ts";

export type ParsedModelSpec =
  { kind: "inherit" } | { kind: "explicit"; provider: string; modelId: string };

export interface GeneratedTitle {
  text: string;
  resolvedModel: string;
}

export function parseModelSpec(model: string): ParsedModelSpec {
  const trimmed = model.trim();
  if (trimmed === "inherit") {
    return { kind: "inherit" };
  }

  const separatorIndex = trimmed.indexOf("/");
  if (separatorIndex <= 0 || separatorIndex === trimmed.length - 1) {
    throw new Error(
      `Invalid title-renamer model ${JSON.stringify(model)}; expected "inherit" or "provider/model-id".`,
    );
  }

  return {
    kind: "explicit",
    provider: trimmed.slice(0, separatorIndex),
    modelId: trimmed.slice(separatorIndex + 1),
  };
}

function formatModelName(model: Model<any>): string {
  return `${model.provider}/${model.id}`;
}

function resolveModel(
  ctx: ExtensionContext,
  config: TitleRenamerConfig,
): Model<any> {
  const parsed = parseModelSpec(config.model);
  if (parsed.kind === "inherit") {
    if (!ctx.model) {
      throw new Error(
        "No current Pi model is available for title-renamer model: inherit.",
      );
    }
    return ctx.model;
  }

  const model = ctx.modelRegistry.find(parsed.provider, parsed.modelId);
  if (!model) {
    throw new Error(
      `Title-renamer model not found: ${parsed.provider}/${parsed.modelId}.`,
    );
  }
  return model;
}

function fallbackTopicFromUserMessage(
  message: string | undefined,
): string | undefined {
  const firstLine = message
    ?.split(/[\r\n]+/)
    .map((line) => line.trim())
    .find(Boolean);
  if (!firstLine) {
    return undefined;
  }

  return firstLine
    .replace(/^\/[\w:-]+\s*/, "")
    .replace(/^[#>*+\-\d.)\s]+/, "")
    .replace(/[`"'“”‘’*_~]/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

export function buildFallbackTitle(
  config: TitleRenamerConfig,
  cwd: string,
  input: Pick<NamingContext, "firstUserMessage"> = {},
): string | undefined {
  const projectName = path.basename(cwd).trim();
  const prefix = config.fallback.prefix.trim();
  const includeProject =
    config.fallback.useProjectName &&
    config.style.includeProject &&
    projectName.length > 0;
  const fallbackTopic = fallbackTopicFromUserMessage(input.firstUserMessage);

  if (fallbackTopic && includeProject) {
    return buildProjectSuffixTitle(
      fallbackTopic,
      projectName,
      config.style.separator,
      config.style.maxChars,
    );
  }
  if (fallbackTopic) {
    return truncateToMax(fallbackTopic, config.style.maxChars);
  }
  if (prefix && includeProject) {
    return `${prefix}${config.style.separator}${projectName}`;
  }
  if (includeProject) {
    return projectName;
  }
  if (prefix) {
    return prefix;
  }
  return undefined;
}

function codePointLength(value: string): number {
  return Array.from(value).length;
}

function truncateToMax(value: string, maxChars: number): string {
  return Array.from(value).slice(0, maxChars).join("").trim();
}

function tailToMax(value: string, maxChars: number): string {
  return Array.from(value).slice(-maxChars).join("").trim();
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function topicWithoutProject(
  title: string,
  projectName: string,
  separator: string,
): string {
  if (title.includes(separator)) {
    return title
      .split(separator)
      .map((part) => part.trim())
      .filter((part) => part && part !== projectName)
      .join(" ")
      .trim();
  }

  if (!title.includes(projectName)) {
    return title;
  }

  return title
    .replace(new RegExp(escapeRegExp(projectName), "g"), " ")
    .replace(/[|｜\-–—:：·•]+$/g, "")
    .replace(/^[|｜\-–—:：·•]+/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

function buildProjectSuffixTitle(
  topic: string,
  projectName: string,
  separator: string,
  maxChars: number,
): string {
  if (!Number.isInteger(maxChars) || maxChars <= 0) {
    return topic.trim() || projectName;
  }

  const trimmedTopic = topic.trim();
  const suffix = `${separator}${projectName}`;
  const suffixLength = codePointLength(suffix);
  if (suffixLength > maxChars) {
    return tailToMax(projectName, maxChars);
  }

  if (!trimmedTopic) {
    return truncateToMax(projectName, maxChars);
  }

  const topicBudget = maxChars - suffixLength;
  const topicPrefix = truncateToMax(trimmedTopic, topicBudget);
  if (!topicPrefix) {
    return truncateToMax(projectName, maxChars);
  }

  return `${topicPrefix}${suffix}`;
}

export function normalizeGeneratedTitle(
  title: string,
  config: TitleRenamerConfig,
  input: Pick<NamingContext, "projectName">,
): string {
  const trimmedTitle = title.trim();
  const projectName = input.projectName?.trim();
  const separator = config.style.separator;
  if (
    !trimmedTitle ||
    !config.style.includeProject ||
    !projectName ||
    !separator
  ) {
    return trimmedTitle;
  }

  return buildProjectSuffixTitle(
    topicWithoutProject(trimmedTitle, projectName, separator),
    projectName,
    separator,
    config.style.maxChars,
  );
}

function buildPrompt(input: NamingContext, config: TitleRenamerConfig): string {
  const lines = [
    "Generate one concise terminal tab title for this Pi conversation.",
    `Language: ${config.style.language}.`,
    `Maximum characters: ${config.style.maxChars}.`,
    "Output rules:",
    "- Output exactly one title.",
    "- Use a single line only.",
    "- Do not use Markdown, bullets, code fences, or quotes.",
    "- Do not explain the title.",
  ];

  if (config.style.includeProject && input.projectName) {
    lines.push(
      `- Include the project name as a suffix in this exact shape: <short topic>${config.style.separator}${input.projectName}.`,
    );
    lines.push("- Do not place the project name before the topic.");
  }

  lines.push("", "Context:");
  if (input.projectName) {
    lines.push(`Project: ${input.projectName}`);
  }
  if (input.cwd) {
    lines.push(`Cwd: ${input.cwd}`);
  }
  if (input.model) {
    lines.push(`Current model: ${input.model}`);
  }
  if (input.firstUserMessage) {
    lines.push("", "First user message:", input.firstUserMessage);
  }
  if (input.firstAssistantMessage) {
    lines.push("", "First assistant message:", input.firstAssistantMessage);
  }

  return lines.join("\n");
}

function createLinkedAbortController(parentSignal: AbortSignal | undefined): {
  controller: AbortController;
  dispose: () => void;
} {
  const controller = new AbortController();
  const abort = () => controller.abort();
  if (parentSignal?.aborted) {
    abort();
  } else {
    parentSignal?.addEventListener("abort", abort, { once: true });
  }

  return {
    controller,
    dispose: () => parentSignal?.removeEventListener("abort", abort),
  };
}

export async function generateTitle(
  ctx: ExtensionContext,
  config: TitleRenamerConfig,
  input: NamingContext,
  signal: AbortSignal | undefined = ctx.signal,
): Promise<GeneratedTitle> {
  const model = resolveModel(ctx, config);
  const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
  if (!auth.ok) {
    throw new Error(auth.error);
  }
  if (!auth.apiKey) {
    throw new Error(
      `No API key available for title-renamer model ${formatModelName(model)}.`,
    );
  }

  const { complete } = await import("@earendil-works/pi-ai/compat");
  const { controller, dispose } = createLinkedAbortController(signal);
  let timeout: ReturnType<typeof setTimeout> | undefined;
  const timeoutPromise = new Promise<never>((_resolve, reject) => {
    timeout = setTimeout(() => {
      controller.abort();
      reject(
        new Error(
          `Title generation timed out after ${config.generation.timeoutMs}ms.`,
        ),
      );
    }, config.generation.timeoutMs);
    (timeout as { unref?: () => void }).unref?.();
  });

  const response = await Promise.race([
    complete(
      model,
      {
        messages: [
          {
            role: "user" as const,
            content: [
              { type: "text" as const, text: buildPrompt(input, config) },
            ],
            timestamp: Date.now(),
          },
        ],
      },
      {
        apiKey: auth.apiKey,
        headers: auth.headers,
        signal: controller.signal,
      },
    ),
    timeoutPromise,
  ]).finally(() => {
    if (timeout) {
      clearTimeout(timeout);
    }
    dispose();
  });

  const text = response.content
    .filter(
      (content): content is { type: "text"; text: string } =>
        content.type === "text",
    )
    .map((content) => content.text)
    .join("\n")
    .trim();

  if (!text) {
    throw new Error("Title-renamer model returned an empty response.");
  }

  return {
    text,
    resolvedModel: formatModelName(model),
  };
}
