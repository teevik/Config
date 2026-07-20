import { basename } from "node:path";
import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";

const SPINNER_FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
const SPINNER_INTERVAL_MS = 120;
const MAX_TITLE_WIDTH = 72;

type TitleState = "ready" | "working";

function sanitizeTitlePart(value: string): string {
  return value
    .replace(/[\x00-\x1f\x7f-\x9f]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function buildTitle(
  pi: ExtensionAPI,
  ctx: ExtensionContext,
  state: TitleState,
  spinnerFrame: string,
): string {
  const project = sanitizeTitlePart(basename(ctx.cwd) || ctx.cwd) || "project";
  const sessionName = pi.getSessionName();
  const session = sessionName ? sanitizeTitlePart(sessionName) : "";
  const activity = state === "working" ? `${spinnerFrame} ` : "";
  const title = `${activity}π ${project}${session ? ` — ${session}` : ""}`;

  return truncateToWidth(title, MAX_TITLE_WIDTH, "…");
}

export default function terminalTitle(pi: ExtensionAPI): void {
  let state: TitleState = "ready";
  let spinnerIndex = 0;
  let animationTimer: ReturnType<typeof setInterval> | undefined;

  const stopAnimation = () => {
    if (!animationTimer) return;
    clearInterval(animationTimer);
    animationTimer = undefined;
  };

  const updateTitle = (ctx: ExtensionContext) => {
    if (ctx.mode !== "tui") return;
    const frame = SPINNER_FRAMES[spinnerIndex] ?? SPINNER_FRAMES[0];
    ctx.ui.setTitle(buildTitle(pi, ctx, state, frame));
  };

  const startAnimation = (ctx: ExtensionContext) => {
    if (ctx.mode !== "tui") return;

    stopAnimation();
    spinnerIndex = 0;
    updateTitle(ctx);
    animationTimer = setInterval(() => {
      spinnerIndex = (spinnerIndex + 1) % SPINNER_FRAMES.length;
      updateTitle(ctx);
    }, SPINNER_INTERVAL_MS);
  };

  pi.on("session_start", (_event, ctx) => {
    stopAnimation();
    state = "ready";
    spinnerIndex = 0;
    updateTitle(ctx);
  });

  pi.on("session_info_changed", (_event, ctx) => {
    updateTitle(ctx);
  });

  pi.on("agent_start", (_event, ctx) => {
    state = "working";
    startAnimation(ctx);
  });

  pi.on("agent_settled", (_event, ctx) => {
    stopAnimation();
    state = "ready";
    spinnerIndex = 0;
    updateTitle(ctx);
  });

  pi.on("session_shutdown", (_event, ctx) => {
    stopAnimation();
    state = "ready";
    spinnerIndex = 0;
    updateTitle(ctx);
  });
}
