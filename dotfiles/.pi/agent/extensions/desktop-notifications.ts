import { spawn, type ChildProcess } from "node:child_process";
import { basename } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const ASK_USER_PROMPT_EVENT = "rpiv:ask-user:prompt";
const COMMAND_TIMEOUT_MS = 5_000;
const NOTIFICATION_EXPIRE_MS = 60_000;

type HyprlandClient = {
  address?: unknown;
  pid?: unknown;
};

export default function desktopNotifications(pi: ExtensionAPI): void {
  const kittyPid = process.env.KITTY_PID;
  const kittyWindowId = process.env.KITTY_WINDOW_ID;
  const kittyListenOn = process.env.KITTY_LISTEN_ON;
  const notificationProcesses = new Set<ChildProcess>();
  const notificationTimers = new Map<
    ChildProcess,
    ReturnType<typeof setTimeout>
  >();

  let projectName = "Pi";
  let notificationsEnabled = false;
  let agentWasRunning = false;
  let hyprlandAddress: string | undefined;

  const rememberHyprlandWindow = async (): Promise<void> => {
    if (!kittyPid) return;

    try {
      const result = await pi.exec("hyprctl", ["-j", "activewindow"], {
        timeout: COMMAND_TIMEOUT_MS,
      });
      const client = JSON.parse(result.stdout) as HyprlandClient;
      if (
        client.pid === Number(kittyPid) &&
        typeof client.address === "string"
      ) {
        hyprlandAddress = client.address;
      }
    } catch {
      // Fall back to Hyprland's PID selector when the address is unavailable.
    }
  };

  const focusPiWindow = async (): Promise<void> => {
    if (!notificationsEnabled) return;

    // Kitty switches to the exact tab and pane containing this Pi process.
    if (kittyListenOn && kittyWindowId) {
      try {
        await pi.exec(
          "kitten",
          [
            "@",
            "--to",
            kittyListenOn,
            "focus-window",
            "--match",
            `id:${kittyWindowId}`,
          ],
          { timeout: COMMAND_TIMEOUT_MS },
        );
      } catch {
        // Hyprland can still focus the outer Kitty window below.
      }
    }

    const windowSelector = hyprlandAddress
      ? `address:${hyprlandAddress}`
      : kittyPid
        ? `pid:${kittyPid}`
        : undefined;
    if (!windowSelector) return;

    try {
      await pi.exec(
        "hyprctl",
        [
          "eval",
          `return hl.dispatch(hl.dsp.focus({ window = "${windowSelector}" }))`,
        ],
        { timeout: COMMAND_TIMEOUT_MS },
      );
    } catch {
      // Clicking a notification is best-effort and must not interrupt Pi.
    }
  };

  const notify = (title: string, body: string, icon: string): void => {
    if (!notificationsEnabled) return;

    try {
      const child = spawn(
        "notify-send",
        [
          "--app-name=Pi",
          `--icon=${icon}`,
          "--urgency=normal",
          `--expire-time=${NOTIFICATION_EXPIRE_MS}`,
          "--action=default=Open Pi",
          title,
          `${body} Click to return.`,
        ],
        { stdio: ["ignore", "pipe", "ignore"] },
      );
      notificationProcesses.add(child);

      let selectedAction = "";
      child.stdout?.setEncoding("utf8");
      child.stdout?.on("data", (chunk: string) => {
        selectedAction += chunk;
      });

      const timer = setTimeout(
        () => child.kill(),
        NOTIFICATION_EXPIRE_MS + 1_000,
      );
      notificationTimers.set(child, timer);

      const cleanup = () => {
        notificationProcesses.delete(child);
        const activeTimer = notificationTimers.get(child);
        if (activeTimer) clearTimeout(activeTimer);
        notificationTimers.delete(child);
      };

      child.once("error", cleanup);
      child.once("close", () => {
        cleanup();
        if (selectedAction.trim() === "default") {
          void focusPiWindow();
        }
      });
    } catch {
      // Desktop notifications are best-effort and must not interrupt Pi.
    }
  };

  pi.on("session_start", async (_event, ctx) => {
    notificationsEnabled = ctx.mode === "tui";
    projectName = basename(ctx.cwd) || ctx.cwd;
    await rememberHyprlandWindow();
  });

  pi.on("agent_start", () => {
    agentWasRunning = true;
  });

  // @juicesharp/rpiv-ask-user-question emits this after validation and
  // immediately before showing its questionnaire UI.
  pi.events.on(ASK_USER_PROMPT_EVENT, () => {
    notify(
      "Pi needs your input",
      `A questionnaire is waiting in ${projectName}.`,
      "dialog-question",
    );
  });

  pi.on("agent_settled", () => {
    if (!agentWasRunning) return;
    agentWasRunning = false;
    notify(
      "Pi is ready",
      `The agent finished in ${projectName}.`,
      "dialog-information",
    );
  });

  pi.on("session_shutdown", () => {
    notificationsEnabled = false;
    agentWasRunning = false;
    for (const child of notificationProcesses) child.kill();
    for (const timer of notificationTimers.values()) clearTimeout(timer);
    notificationProcesses.clear();
    notificationTimers.clear();
  });
}
