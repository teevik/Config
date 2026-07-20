import { basename } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const ASK_USER_PROMPT_EVENT = "rpiv:ask-user:prompt";
const NOTIFICATION_TIMEOUT_MS = 5_000;

export default function desktopNotifications(pi: ExtensionAPI): void {
  let projectName = "Pi";
  let notificationsEnabled = false;
  let agentWasRunning = false;

  const notify = async (
    title: string,
    body: string,
    icon: string,
  ): Promise<void> => {
    if (!notificationsEnabled) return;

    try {
      await pi.exec(
        "notify-send",
        ["--app-name=Pi", `--icon=${icon}`, "--urgency=normal", title, body],
        { timeout: NOTIFICATION_TIMEOUT_MS },
      );
    } catch {
      // Desktop notifications are best-effort and must not interrupt Pi.
    }
  };

  pi.on("session_start", (_event, ctx) => {
    notificationsEnabled = ctx.mode === "tui";
    projectName = basename(ctx.cwd) || ctx.cwd;
  });

  pi.on("agent_start", () => {
    agentWasRunning = true;
  });

  // @juicesharp/rpiv-ask-user-question emits this after validation and
  // immediately before showing its questionnaire UI.
  pi.events.on(ASK_USER_PROMPT_EVENT, () => {
    void notify(
      "Pi needs your input",
      `A questionnaire is waiting in ${projectName}.`,
      "dialog-question",
    );
  });

  pi.on("agent_settled", async () => {
    if (!agentWasRunning) return;
    agentWasRunning = false;
    await notify(
      "Pi is ready",
      `The agent finished in ${projectName}.`,
      "dialog-information",
    );
  });

  pi.on("session_shutdown", () => {
    notificationsEnabled = false;
    agentWasRunning = false;
  });
}
