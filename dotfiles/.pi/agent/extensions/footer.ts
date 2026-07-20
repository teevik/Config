import { basename, isAbsolute, relative, resolve, sep } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const STATE_EVENT = "codex-fast:state";
const NIXOS_ICON = "";
const SPINNER_FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];

type FastState = {
  enabled: boolean;
  active: boolean;
};

type ActiveTool = {
  label: string;
  startedAt: number;
};

type LastRun = {
  durationMs: number;
  toolCount: number;
  errorCount: number;
};

function isFastState(value: unknown): value is FastState {
  if (typeof value !== "object" || value === null) return false;
  const state = value as Record<string, unknown>;
  return (
    typeof state.enabled === "boolean" && typeof state.active === "boolean"
  );
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function formatTokens(count: number): string {
  if (count < 1_000) return count.toString();
  if (count < 10_000) return `${(count / 1_000).toFixed(1)}k`;
  if (count < 1_000_000) return `${Math.round(count / 1_000)}k`;
  if (count < 10_000_000) return `${(count / 1_000_000).toFixed(1)}M`;
  return `${Math.round(count / 1_000_000)}M`;
}

function formatDuration(durationMs: number): string {
  const seconds = durationMs / 1_000;
  if (seconds < 10) return `${seconds.toFixed(1)}s`;

  const roundedSeconds = Math.round(seconds);
  if (roundedSeconds < 60) return `${roundedSeconds}s`;
  const minutes = Math.floor(roundedSeconds / 60);
  const remainingSeconds = roundedSeconds % 60;
  return `${minutes}m${remainingSeconds.toString().padStart(2, "0")}s`;
}

function formatCwd(cwd: string, home: string | undefined): string {
  if (!home) return cwd;

  const resolvedCwd = resolve(cwd);
  const resolvedHome = resolve(home);
  const relativeToHome = relative(resolvedHome, resolvedCwd);
  const isInsideHome =
    relativeToHome === "" ||
    (relativeToHome !== ".." &&
      !relativeToHome.startsWith(`..${sep}`) &&
      !isAbsolute(relativeToHome));

  if (!isInsideHome) return cwd;
  return relativeToHome === "" ? "~" : `~${sep}${relativeToHome}`;
}

function sanitizeStatus(text: string): string {
  return text
    .replace(/[\r\n\t]/g, " ")
    .replace(/ +/g, " ")
    .trim();
}

function formatToolLabel(toolName: string, args: unknown): string {
  if (!isRecord(args)) return toolName;

  const path = args.path;
  if (typeof path === "string" && path.length > 0) {
    return `${toolName} ${truncateToWidth(basename(path), 30, "…")}`;
  }

  const query = args.query;
  if (typeof query === "string" && query.length > 0) {
    return `${toolName} ${truncateToWidth(sanitizeStatus(query), 30, "…")}`;
  }

  const command = args.command;
  if (typeof command === "string" && command.length > 0) {
    return `${toolName} ${truncateToWidth(sanitizeStatus(command), 30, "…")}`;
  }

  const url = args.url;
  if (typeof url === "string" && url.length > 0) {
    return `${toolName} ${truncateToWidth(sanitizeStatus(url), 30, "…")}`;
  }

  return toolName;
}

function alignSides(left: string, right: string, width: number): string {
  if (width <= 0) return "";

  const gap = 2;
  const leftWidth = visibleWidth(left);
  const rightWidth = visibleWidth(right);
  if (leftWidth + gap + rightWidth <= width) {
    return left + " ".repeat(width - leftWidth - rightWidth) + right;
  }

  const rightLimit = Math.max(0, Math.floor(width * 0.55));
  const fittedRight = truncateToWidth(right, rightLimit, "");
  const fittedRightWidth = visibleWidth(fittedRight);
  const leftLimit = Math.max(0, width - fittedRightWidth - gap);
  const fittedLeft = truncateToWidth(left, leftLimit, "…");
  const fittedLeftWidth = visibleWidth(fittedLeft);
  const padding = " ".repeat(
    Math.max(0, width - fittedLeftWidth - fittedRightWidth),
  );
  return fittedLeft + padding + fittedRight;
}

// An adaptive Catppuccin mission-control footer with live tool activity.
export default function footer(pi: ExtensionAPI): void {
  let fastState: FastState = { enabled: false, active: false };
  let requestRender: (() => void) | undefined;
  let animationTimer: ReturnType<typeof setInterval> | undefined;
  let spinnerIndex = 0;
  let runStartedAt: number | undefined;
  let toolCount = 0;
  let errorCount = 0;
  let lastRun: LastRun | undefined;
  const activeTools = new Map<string, ActiveTool>();

  const renderNow = () => requestRender?.();

  const stopAnimation = () => {
    if (!animationTimer) return;
    clearInterval(animationTimer);
    animationTimer = undefined;
  };

  const startAnimation = () => {
    if (animationTimer || !requestRender) return;
    animationTimer = setInterval(() => {
      spinnerIndex = (spinnerIndex + 1) % SPINNER_FRAMES.length;
      renderNow();
    }, 100);
  };

  pi.events.on(STATE_EVENT, (value) => {
    if (!isFastState(value)) return;
    fastState = value;
    renderNow();
  });

  pi.on("agent_start", () => {
    if (runStartedAt === undefined) {
      runStartedAt = Date.now();
      toolCount = 0;
      errorCount = 0;
    }
    startAnimation();
    renderNow();
  });

  pi.on("tool_execution_start", (event) => {
    activeTools.set(event.toolCallId, {
      label: formatToolLabel(event.toolName, event.args),
      startedAt: Date.now(),
    });
    startAnimation();
    renderNow();
  });

  pi.on("tool_execution_end", (event) => {
    activeTools.delete(event.toolCallId);
    toolCount += 1;
    if (event.isError) errorCount += 1;
    renderNow();
  });

  pi.on("agent_settled", () => {
    if (runStartedAt !== undefined) {
      lastRun = {
        durationMs: Date.now() - runStartedAt,
        toolCount,
        errorCount,
      };
    }
    runStartedAt = undefined;
    activeTools.clear();
    stopAnimation();
    renderNow();
  });

  pi.on("model_select", renderNow);
  pi.on("thinking_level_select", renderNow);
  pi.on("session_info_changed", renderNow);

  pi.on("session_shutdown", () => {
    stopAnimation();
    requestRender = undefined;
    activeTools.clear();
  });

  pi.on("session_start", async (_event, ctx) => {
    if (ctx.mode !== "tui") return;

    ctx.ui.setFooter((tui, theme, footerData) => {
      const footerRender = () => tui.requestRender();
      requestRender = footerRender;
      if (runStartedAt !== undefined) startAnimation();
      const unsubscribeBranch = footerData.onBranchChange(footerRender);

      return {
        invalidate() {},
        dispose() {
          if (requestRender === footerRender) requestRender = undefined;
          stopAnimation();
          unsubscribeBranch();
        },
        render(width: number): string[] {
          let totalInput = 0;
          let totalOutput = 0;
          let totalCacheRead = 0;
          let totalCacheWrite = 0;
          let totalCost = 0;
          let latestCacheHitRate: number | undefined;

          for (const entry of ctx.sessionManager.getBranch()) {
            if (entry.type !== "message" || entry.message.role !== "assistant")
              continue;

            const usage = entry.message.usage;
            totalInput += usage.input;
            totalOutput += usage.output;
            totalCacheRead += usage.cacheRead;
            totalCacheWrite += usage.cacheWrite;
            totalCost += usage.cost.total;

            const latestPromptTokens =
              usage.input + usage.cacheRead + usage.cacheWrite;
            latestCacheHitRate =
              latestPromptTokens > 0
                ? (usage.cacheRead / latestPromptTokens) * 100
                : undefined;
          }

          const separator = theme.fg("dim", " · ");
          const wide = width >= 120;
          const medium = width >= 80;

          const cwd = formatCwd(
            ctx.cwd,
            process.env.HOME ?? process.env.USERPROFILE,
          );
          const locationParts = [
            theme.bold(theme.fg("accent", NIXOS_ICON)),
            theme.fg("mdLink", cwd),
          ];
          const branch = footerData.getGitBranch();
          if (branch) locationParts.push(theme.fg("mdCode", ` ${branch}`));
          const sessionName = ctx.sessionManager.getSessionName();
          if (sessionName)
            locationParts.push(theme.fg("mdHeading", sessionName));
          const locationLine = truncateToWidth(
            locationParts.join(separator),
            width,
            theme.fg("dim", "…"),
          );

          let activity: string;
          if (runStartedAt !== undefined) {
            const currentTool = Array.from(activeTools.values()).at(-1);
            const label = currentTool?.label ?? "thinking";
            const startedAt = currentTool?.startedAt ?? runStartedAt;
            activity =
              theme.fg(
                "accent",
                SPINNER_FRAMES[spinnerIndex] ?? SPINNER_FRAMES[0],
              ) +
              " " +
              theme.fg("text", label) +
              separator +
              theme.fg("muted", formatDuration(Date.now() - startedAt));
          } else if (lastRun) {
            const resultLabel =
              lastRun.toolCount === 0
                ? "answered"
                : `${lastRun.toolCount} tool${lastRun.toolCount === 1 ? "" : "s"}`;
            activity =
              theme.fg("success", "✓") +
              " " +
              theme.fg("text", resultLabel) +
              separator +
              theme.fg("muted", formatDuration(lastRun.durationMs));
            if (lastRun.errorCount > 0) {
              activity +=
                separator +
                theme.fg(
                  "error",
                  `${lastRun.errorCount} error${lastRun.errorCount === 1 ? "" : "s"}`,
                );
            }
          } else {
            activity = theme.fg("muted", "ready");
          }

          const stats: string[] = [];
          if (medium && totalInput > 0) {
            stats.push(theme.fg("mdLink", `↑${formatTokens(totalInput)}`));
          }
          if (medium && totalOutput > 0) {
            stats.push(theme.fg("success", `↓${formatTokens(totalOutput)}`));
          }
          if (wide && (totalCacheRead > 0 || totalCacheWrite > 0)) {
            const cacheText =
              latestCacheHitRate === undefined
                ? `cache R${formatTokens(totalCacheRead)} W${formatTokens(totalCacheWrite)}`
                : `cache ${latestCacheHitRate.toFixed(0)}%`;
            stats.push(theme.fg("mdCode", cacheText));
          }
          const usingSubscription = ctx.model
            ? ctx.modelRegistry.isUsingOAuth(ctx.model)
            : false;
          if (wide && (totalCost > 0 || usingSubscription)) {
            stats.push(
              theme.fg(
                "mdHeading",
                `$${totalCost.toFixed(3)}${usingSubscription ? " sub" : ""}`,
              ),
            );
          }
          const left =
            stats.length > 0 ? `${activity}  ${stats.join(" ")}` : activity;

          const contextUsage = ctx.getContextUsage();
          const contextWindow =
            contextUsage?.contextWindow ?? ctx.model?.contextWindow ?? 0;
          const contextPercent = contextUsage?.percent;
          let contextText: string;
          if (contextPercent === null || contextPercent === undefined) {
            contextText = theme.fg(
              "muted",
              wide ? `ctx ?/${formatTokens(contextWindow)}` : "ctx ?",
            );
          } else {
            const percent = Math.max(0, Math.min(100, contextPercent));
            const segmentCount = wide ? 10 : medium ? 8 : 0;
            const filledCount = Math.round((percent / 100) * segmentCount);
            const filled = "█".repeat(filledCount);
            const empty = "░".repeat(segmentCount - filledCount);
            const percentText = `${Math.round(percent)}%${
              wide ? `/${formatTokens(contextWindow)}` : ""
            }`;
            const colorized = (text: string) => {
              if (percent > 90) return theme.fg("error", text);
              if (percent > 70) return theme.fg("warning", text);
              return theme.fg("success", text);
            };
            contextText =
              theme.fg("dim", "ctx ") +
              (segmentCount > 0
                ? `${colorized(filled)}${theme.fg("dim", empty)} `
                : "") +
              colorized(percentText);
          }

          const modelParts: string[] = [];
          const modelName = ctx.model?.id ?? "no-model";
          const providerPrefix =
            wide && footerData.getAvailableProviderCount() > 1 && ctx.model
              ? `${ctx.model.provider}/`
              : "";
          modelParts.push(theme.fg("accent", `${providerPrefix}${modelName}`));

          if (ctx.model?.reasoning) {
            const thinkingLevel = pi.getThinkingLevel();
            const thinkingLabel =
              thinkingLevel === "off" ? "off" : thinkingLevel;
            switch (thinkingLevel) {
              case "off":
                modelParts.push(theme.fg("thinkingOff", thinkingLabel));
                break;
              case "minimal":
                modelParts.push(theme.fg("thinkingMinimal", thinkingLabel));
                break;
              case "low":
                modelParts.push(theme.fg("thinkingLow", thinkingLabel));
                break;
              case "medium":
                modelParts.push(theme.fg("thinkingMedium", thinkingLabel));
                break;
              case "high":
                modelParts.push(theme.fg("thinkingHigh", thinkingLabel));
                break;
              case "xhigh":
                modelParts.push(theme.fg("thinkingXhigh", thinkingLabel));
                break;
              case "max":
                modelParts.push(theme.fg("thinkingMax", thinkingLabel));
                break;
            }
          }

          if (fastState.enabled && (medium || fastState.active)) {
            modelParts.push(
              fastState.active
                ? theme.fg("warning", "⚡ fast")
                : theme.fg("dim", "fast inactive"),
            );
          }
          if (process.env.PI_EXPERIMENTAL === "1" && wide) {
            modelParts.push(theme.bold(theme.fg("warning", "xp")));
          }

          const right = [contextText, modelParts.join(separator)].join(
            separator,
          );
          const statusLine = alignSides(left, right, width);
          const lines = [locationLine, statusLine];

          const extensionStatuses = footerData.getExtensionStatuses();
          if (extensionStatuses.size > 0) {
            const extensionStatusLine = Array.from(extensionStatuses.entries())
              .sort(([a], [b]) => a.localeCompare(b))
              .map(([, text]) => sanitizeStatus(text))
              .join(" ");
            lines.push(
              truncateToWidth(extensionStatusLine, width, theme.fg("dim", "…")),
            );
          }

          return lines;
        },
      };
    });
  });
}
