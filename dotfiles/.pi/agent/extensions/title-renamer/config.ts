import fs from "node:fs";
import os from "node:os";
import path from "node:path";

export interface TitleRenamerConfig {
  enabled: boolean;
  auto: boolean;
  trigger: "first-user-message" | "first-agent-end";
  model: string;
  apply: {
    terminalTitle: boolean;
    sessionName: boolean;
    overwriteSessionName: boolean;
  };
  style: {
    language: string;
    maxChars: number;
    includeProject: boolean;
    separator: string;
  };
  input: {
    includeFirstUserMessage: boolean;
    includeFirstAssistantMessage: boolean;
    includeCwd: boolean;
    includeModel: boolean;
  };
  generation: {
    timeoutMs: number;
  };
  fallback: {
    useProjectName: boolean;
    prefix: string;
  };
}

export interface LoadedConfig {
  config: TitleRenamerConfig;
  warnings: string[];
  paths: {
    global: string;
    project: string;
  };
}

export interface LoadConfigOptions {
  homeDir?: string;
  readFile?: (filePath: string) => string;
  exists?: (filePath: string) => boolean;
}

export const DEFAULT_CONFIG: TitleRenamerConfig = {
  enabled: true,
  auto: true,
  trigger: "first-user-message",
  model: "inherit",
  apply: {
    terminalTitle: true,
    sessionName: false,
    overwriteSessionName: false,
  },
  style: {
    language: "en",
    maxChars: 24,
    includeProject: true,
    separator: "｜",
  },
  input: {
    includeFirstUserMessage: true,
    includeFirstAssistantMessage: true,
    includeCwd: true,
    includeModel: false,
  },
  generation: {
    timeoutMs: 15000,
  },
  fallback: {
    useProjectName: true,
    prefix: "Pi",
  },
};

const cloneConfig = (config: TitleRenamerConfig): TitleRenamerConfig => ({
  ...config,
  apply: { ...config.apply },
  style: { ...config.style },
  input: { ...config.input },
  generation: { ...config.generation },
  fallback: { ...config.fallback },
});

const isPlainObject = (value: unknown): value is Record<string, unknown> =>
  !!value && typeof value === "object" && !Array.isArray(value);

export function mergeConfig(
  base: TitleRenamerConfig,
  override: unknown,
): TitleRenamerConfig {
  if (!isPlainObject(override)) {
    return cloneConfig(base);
  }

  const merged = cloneConfig(base) as unknown as Record<string, unknown>;
  for (const [key, value] of Object.entries(override)) {
    const current = merged[key];
    if (isPlainObject(current) && isPlainObject(value)) {
      merged[key] = { ...current, ...value };
    } else {
      merged[key] = value;
    }
  }

  return merged as unknown as TitleRenamerConfig;
}

function validateBoolean(
  value: unknown,
  fallback: boolean,
  key: string,
  warnings: string[],
): boolean {
  if (typeof value === "boolean") {
    return value;
  }
  warnings.push(
    `Invalid title-renamer config ${key}; using default ${String(fallback)}.`,
  );
  return fallback;
}

function validateString(
  value: unknown,
  fallback: string,
  key: string,
  warnings: string[],
): string {
  if (typeof value === "string") {
    return value;
  }
  warnings.push(
    `Invalid title-renamer config ${key}; using default ${JSON.stringify(fallback)}.`,
  );
  return fallback;
}

function validatePositiveInteger(
  value: unknown,
  fallback: number,
  key: string,
  warnings: string[],
): number {
  if (Number.isInteger(value) && typeof value === "number" && value > 0) {
    return value;
  }
  warnings.push(
    `Invalid title-renamer config ${key}; using default ${String(fallback)}.`,
  );
  return fallback;
}

export function validateConfig(input: unknown): {
  config: TitleRenamerConfig;
  warnings: string[];
} {
  const warnings: string[] = [];
  const raw = isPlainObject(input) ? input : {};
  if (!isPlainObject(input)) {
    warnings.push("Invalid title-renamer config root; using defaults.");
  }

  const rawApply = isPlainObject(raw.apply) ? raw.apply : {};
  const rawStyle = isPlainObject(raw.style) ? raw.style : {};
  const rawInput = isPlainObject(raw.input) ? raw.input : {};
  const rawGeneration = isPlainObject(raw.generation) ? raw.generation : {};
  const rawFallback = isPlainObject(raw.fallback) ? raw.fallback : {};

  const triggerValue = validateString(
    raw.trigger,
    DEFAULT_CONFIG.trigger,
    "trigger",
    warnings,
  );
  const supportedTriggers: TitleRenamerConfig["trigger"][] = [
    "first-user-message",
    "first-agent-end",
  ];
  const trigger: TitleRenamerConfig["trigger"] = supportedTriggers.includes(
    triggerValue as TitleRenamerConfig["trigger"],
  )
    ? (triggerValue as TitleRenamerConfig["trigger"])
    : DEFAULT_CONFIG.trigger;
  if (
    !supportedTriggers.includes(triggerValue as TitleRenamerConfig["trigger"])
  ) {
    warnings.push(
      `Unsupported title-renamer config trigger ${JSON.stringify(triggerValue)}; using default ${DEFAULT_CONFIG.trigger}.`,
    );
  }

  return {
    config: {
      enabled: validateBoolean(
        raw.enabled,
        DEFAULT_CONFIG.enabled,
        "enabled",
        warnings,
      ),
      auto: validateBoolean(raw.auto, DEFAULT_CONFIG.auto, "auto", warnings),
      trigger,
      model:
        validateString(
          raw.model,
          DEFAULT_CONFIG.model,
          "model",
          warnings,
        ).trim() || DEFAULT_CONFIG.model,
      apply: {
        terminalTitle: validateBoolean(
          rawApply.terminalTitle,
          DEFAULT_CONFIG.apply.terminalTitle,
          "apply.terminalTitle",
          warnings,
        ),
        sessionName: validateBoolean(
          rawApply.sessionName,
          DEFAULT_CONFIG.apply.sessionName,
          "apply.sessionName",
          warnings,
        ),
        overwriteSessionName: validateBoolean(
          rawApply.overwriteSessionName,
          DEFAULT_CONFIG.apply.overwriteSessionName,
          "apply.overwriteSessionName",
          warnings,
        ),
      },
      style: {
        language: validateString(
          rawStyle.language,
          DEFAULT_CONFIG.style.language,
          "style.language",
          warnings,
        ),
        maxChars: validatePositiveInteger(
          rawStyle.maxChars,
          DEFAULT_CONFIG.style.maxChars,
          "style.maxChars",
          warnings,
        ),
        includeProject: validateBoolean(
          rawStyle.includeProject,
          DEFAULT_CONFIG.style.includeProject,
          "style.includeProject",
          warnings,
        ),
        separator: validateString(
          rawStyle.separator,
          DEFAULT_CONFIG.style.separator,
          "style.separator",
          warnings,
        ),
      },
      input: {
        includeFirstUserMessage: validateBoolean(
          rawInput.includeFirstUserMessage,
          DEFAULT_CONFIG.input.includeFirstUserMessage,
          "input.includeFirstUserMessage",
          warnings,
        ),
        includeFirstAssistantMessage: validateBoolean(
          rawInput.includeFirstAssistantMessage,
          DEFAULT_CONFIG.input.includeFirstAssistantMessage,
          "input.includeFirstAssistantMessage",
          warnings,
        ),
        includeCwd: validateBoolean(
          rawInput.includeCwd,
          DEFAULT_CONFIG.input.includeCwd,
          "input.includeCwd",
          warnings,
        ),
        includeModel: validateBoolean(
          rawInput.includeModel,
          DEFAULT_CONFIG.input.includeModel,
          "input.includeModel",
          warnings,
        ),
      },
      generation: {
        timeoutMs: validatePositiveInteger(
          rawGeneration.timeoutMs,
          DEFAULT_CONFIG.generation.timeoutMs,
          "generation.timeoutMs",
          warnings,
        ),
      },
      fallback: {
        useProjectName: validateBoolean(
          rawFallback.useProjectName,
          DEFAULT_CONFIG.fallback.useProjectName,
          "fallback.useProjectName",
          warnings,
        ),
        prefix: validateString(
          rawFallback.prefix,
          DEFAULT_CONFIG.fallback.prefix,
          "fallback.prefix",
          warnings,
        ),
      },
    },
    warnings,
  };
}

function readConfigFile(
  filePath: string,
  options: Required<Pick<LoadConfigOptions, "readFile" | "exists">>,
): { value?: unknown; warnings: string[] } {
  if (!options.exists(filePath)) {
    return { warnings: [] };
  }

  try {
    return { value: JSON.parse(options.readFile(filePath)), warnings: [] };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return {
      warnings: [`Could not read title-renamer config ${filePath}: ${message}`],
    };
  }
}

export function loadConfig(
  cwd = process.cwd(),
  options: LoadConfigOptions = {},
): LoadedConfig {
  const homeDir = options.homeDir ?? os.homedir();
  const globalPath = path.join(homeDir, ".pi", "agent", "title-renamer.json");
  const projectPath = path.join(cwd, ".pi", "title-renamer.json");
  const fsOptions = {
    readFile:
      options.readFile ??
      ((filePath: string) => fs.readFileSync(filePath, "utf8")),
    exists: options.exists ?? ((filePath: string) => fs.existsSync(filePath)),
  };

  const warnings: string[] = [];
  const globalConfig = readConfigFile(globalPath, fsOptions);
  warnings.push(...globalConfig.warnings);
  const projectConfig = readConfigFile(projectPath, fsOptions);
  warnings.push(...projectConfig.warnings);

  let merged = cloneConfig(DEFAULT_CONFIG);
  if (globalConfig.value !== undefined) {
    merged = mergeConfig(merged, globalConfig.value);
  }
  if (projectConfig.value !== undefined) {
    merged = mergeConfig(merged, projectConfig.value);
  }

  const validated = validateConfig(merged);
  warnings.push(...validated.warnings);

  return {
    config: validated.config,
    warnings,
    paths: {
      global: globalPath,
      project: projectPath,
    },
  };
}
