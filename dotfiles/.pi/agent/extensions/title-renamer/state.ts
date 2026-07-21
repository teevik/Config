import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export const STATE_CUSTOM_TYPE = "title-renamer-state";

export interface TitleRenamerState {
  autoRenamed: boolean;
  title?: string;
  triggeredAt: string;
  model: string;
  resolvedModel?: string;
  manual: boolean;
  warnings: string[];
  reset?: boolean;
}

type CustomEntry = {
  type: string;
  customType?: string;
  data?: unknown;
};

function isTitleRenamerState(value: unknown): value is TitleRenamerState {
  if (!value || typeof value !== "object") {
    return false;
  }
  const state = value as Partial<TitleRenamerState>;
  return (
    typeof state.autoRenamed === "boolean" &&
    typeof state.triggeredAt === "string" &&
    typeof state.manual === "boolean"
  );
}

export function getLatestTitleRenamerState(
  entries: readonly CustomEntry[],
): TitleRenamerState | undefined {
  for (let index = entries.length - 1; index >= 0; index--) {
    const entry = entries[index];
    if (
      entry?.type === "custom" &&
      entry.customType === STATE_CUSTOM_TYPE &&
      isTitleRenamerState(entry.data)
    ) {
      return entry.data;
    }
  }
  return undefined;
}

export function getLatestResetIndex(entries: readonly CustomEntry[]): number {
  for (let index = entries.length - 1; index >= 0; index--) {
    const entry = entries[index];
    if (
      entry?.type === "custom" &&
      entry.customType === STATE_CUSTOM_TYPE &&
      isTitleRenamerState(entry.data) &&
      entry.data.reset
    ) {
      return index;
    }
  }
  return -1;
}

export function hasAutoRenamed(entries: readonly CustomEntry[]): boolean {
  for (let index = entries.length - 1; index >= 0; index--) {
    const entry = entries[index];
    if (
      entry?.type !== "custom" ||
      entry.customType !== STATE_CUSTOM_TYPE ||
      !isTitleRenamerState(entry.data)
    ) {
      continue;
    }
    if (entry.data.reset) {
      return false;
    }
    if (entry.data.autoRenamed) {
      return true;
    }
  }
  return false;
}

export function blocksAutoRename(entries: readonly CustomEntry[]): boolean {
  for (let index = entries.length - 1; index >= 0; index--) {
    const entry = entries[index];
    if (
      entry?.type !== "custom" ||
      entry.customType !== STATE_CUSTOM_TYPE ||
      !isTitleRenamerState(entry.data)
    ) {
      continue;
    }
    if (entry.data.reset) {
      return false;
    }
    if (entry.data.autoRenamed || (entry.data.manual && !!entry.data.title)) {
      return true;
    }
  }
  return false;
}

export function getLatestTitleToReapply(
  entries: readonly CustomEntry[],
): string | undefined {
  for (let index = entries.length - 1; index >= 0; index--) {
    const entry = entries[index];
    if (
      entry?.type === "custom" &&
      entry.customType === STATE_CUSTOM_TYPE &&
      isTitleRenamerState(entry.data) &&
      entry.data.title
    ) {
      return entry.data.title;
    }
  }
  return undefined;
}

export function makeTitleRenamerState(input: {
  autoRenamed: boolean;
  title?: string;
  model: string;
  resolvedModel?: string;
  manual: boolean;
  warnings?: string[];
  reset?: boolean;
  now?: Date;
}): TitleRenamerState {
  return {
    autoRenamed: input.autoRenamed,
    title: input.title,
    triggeredAt: (input.now ?? new Date()).toISOString(),
    model: input.model,
    resolvedModel: input.resolvedModel,
    manual: input.manual,
    warnings: input.warnings ?? [],
    reset: input.reset,
  };
}

export function appendTitleRenamerState(
  pi: Pick<ExtensionAPI, "appendEntry">,
  state: TitleRenamerState,
): void {
  pi.appendEntry(STATE_CUSTOM_TYPE, state);
}
