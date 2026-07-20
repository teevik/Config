import { isAbsolute, relative, resolve, sep } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const STATE_EVENT = "codex-fast:state";

type FastState = {
	enabled: boolean;
	active: boolean;
};

function isFastState(value: unknown): value is FastState {
	if (typeof value !== "object" || value === null) return false;
	const state = value as Record<string, unknown>;
	return typeof state.enabled === "boolean" && typeof state.active === "boolean";
}

function formatTokens(count: number): string {
	if (count < 1_000) return count.toString();
	if (count < 10_000) return `${(count / 1_000).toFixed(1)}k`;
	if (count < 1_000_000) return `${Math.round(count / 1_000)}k`;
	if (count < 10_000_000) return `${(count / 1_000_000).toFixed(1)}M`;
	return `${Math.round(count / 1_000_000)}M`;
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
	return text.replace(/[\r\n\t]/g, " ").replace(/ +/g, " ").trim();
}

// Mirrors Pi's built-in footer layout; keep local presentation changes in this module.
export default function footer(pi: ExtensionAPI): void {
	let fastState: FastState = { enabled: false, active: false };
	let requestRender: (() => void) | undefined;

	pi.events.on(STATE_EVENT, (value) => {
		if (!isFastState(value)) return;
		fastState = value;
		requestRender?.();
	});

	pi.on("session_start", async (_event, ctx) => {
		if (ctx.mode !== "tui") return;

		ctx.ui.setFooter((tui, theme, footerData) => {
			requestRender = () => tui.requestRender();
			const unsubscribeBranch = footerData.onBranchChange(() => tui.requestRender());

			return {
				invalidate() {},
				dispose() {
					if (requestRender) requestRender = undefined;
					unsubscribeBranch();
				},
				render(width: number): string[] {
					let totalInput = 0;
					let totalOutput = 0;
					let totalCacheRead = 0;
					let totalCacheWrite = 0;
					let totalCost = 0;
					let latestCacheHitRate: number | undefined;

					for (const entry of ctx.sessionManager.getEntries()) {
						if (entry.type !== "message" || entry.message.role !== "assistant") continue;

						const usage = entry.message.usage;
						totalInput += usage.input;
						totalOutput += usage.output;
						totalCacheRead += usage.cacheRead;
						totalCacheWrite += usage.cacheWrite;
						totalCost += usage.cost.total;

						const latestPromptTokens = usage.input + usage.cacheRead + usage.cacheWrite;
						latestCacheHitRate =
							latestPromptTokens > 0
								? (usage.cacheRead / latestPromptTokens) * 100
								: undefined;
					}

					const contextUsage = ctx.getContextUsage();
					const contextWindow = contextUsage?.contextWindow ?? ctx.model?.contextWindow ?? 0;
					const contextPercentValue = contextUsage?.percent ?? 0;
					const contextPercent =
						contextUsage?.percent === null ? "?" : contextPercentValue.toFixed(1);

					let cwd = formatCwd(ctx.cwd, process.env.HOME ?? process.env.USERPROFILE);
					const branch = footerData.getGitBranch();
					if (branch) cwd += ` (${branch})`;

					const sessionName = ctx.sessionManager.getSessionName();
					if (sessionName) cwd += ` • ${sessionName}`;

					const statsParts: string[] = [];
					if (totalInput) statsParts.push(`↑${formatTokens(totalInput)}`);
					if (totalOutput) statsParts.push(`↓${formatTokens(totalOutput)}`);
					if (totalCacheRead) statsParts.push(`R${formatTokens(totalCacheRead)}`);
					if (totalCacheWrite) statsParts.push(`W${formatTokens(totalCacheWrite)}`);
					if (
						(totalCacheRead > 0 || totalCacheWrite > 0) &&
						latestCacheHitRate !== undefined
					) {
						statsParts.push(`CH${latestCacheHitRate.toFixed(1)}%`);
					}

					const usingSubscription = ctx.model
						? ctx.modelRegistry.isUsingOAuth(ctx.model)
						: false;
					if (totalCost || usingSubscription) {
						statsParts.push(
							`$${totalCost.toFixed(3)}${usingSubscription ? " (sub)" : ""}`,
						);
					}

					const contextDisplay =
						contextPercent === "?"
							? `?/${formatTokens(contextWindow)} (auto)`
							: `${contextPercent}%/${formatTokens(contextWindow)} (auto)`;
					if (contextPercentValue > 90) {
						statsParts.push(theme.fg("error", contextDisplay));
					} else if (contextPercentValue > 70) {
						statsParts.push(theme.fg("warning", contextDisplay));
					} else {
						statsParts.push(contextDisplay);
					}

					if (process.env.PI_EXPERIMENTAL === "1") {
						statsParts.push(
							`${theme.fg("dim", "•")} ${theme.bold(theme.fg("warning", "xp"))}`,
						);
					}

					let statsLeft = statsParts.join(" ");
					let statsLeftWidth = visibleWidth(statsLeft);
					if (statsLeftWidth > width) {
						statsLeft = truncateToWidth(statsLeft, width, "...");
						statsLeftWidth = visibleWidth(statsLeft);
					}

					const modelName = ctx.model?.id ?? "no-model";
					let rightSideWithoutProvider = modelName;
					if (ctx.model?.reasoning) {
						const thinkingLevel = pi.getThinkingLevel();
						rightSideWithoutProvider =
							thinkingLevel === "off"
								? `${modelName} • thinking off`
								: `${modelName} • ${thinkingLevel}`;
					}

					// Local customization: append behavior-only extension state to the model details.
					if (fastState.enabled) {
						rightSideWithoutProvider += fastState.active
							? " • fast"
							: " • fast (inactive)";
					}

					const minimumPadding = 2;
					let rightSide = rightSideWithoutProvider;
					if (footerData.getAvailableProviderCount() > 1 && ctx.model) {
						rightSide = `(${ctx.model.provider}) ${rightSideWithoutProvider}`;
						if (
							statsLeftWidth + minimumPadding + visibleWidth(rightSide) > width
						) {
							rightSide = rightSideWithoutProvider;
						}
					}

					const rightSideWidth = visibleWidth(rightSide);
					let statsLine: string;
					if (statsLeftWidth + minimumPadding + rightSideWidth <= width) {
						const padding = " ".repeat(width - statsLeftWidth - rightSideWidth);
						statsLine = statsLeft + padding + rightSide;
					} else {
						const availableForRight = width - statsLeftWidth - minimumPadding;
						if (availableForRight > 0) {
							const truncatedRight = truncateToWidth(rightSide, availableForRight, "");
							const padding = " ".repeat(
								Math.max(0, width - statsLeftWidth - visibleWidth(truncatedRight)),
							);
							statsLine = statsLeft + padding + truncatedRight;
						} else {
							statsLine = statsLeft;
						}
					}

					const lines = [
						truncateToWidth(theme.fg("dim", cwd), width, theme.fg("dim", "...")),
						theme.fg("dim", statsLeft) +
							theme.fg("dim", statsLine.slice(statsLeft.length)),
					];

					const extensionStatuses = footerData.getExtensionStatuses();
					if (extensionStatuses.size > 0) {
						const statusLine = Array.from(extensionStatuses.entries())
							.sort(([a], [b]) => a.localeCompare(b))
							.map(([, text]) => sanitizeStatus(text))
							.join(" ");
						lines.push(
							truncateToWidth(statusLine, width, theme.fg("dim", "...")),
						);
					}

					return lines;
				},
			};
		});
	});
}
