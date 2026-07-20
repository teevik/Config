import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Key } from "@earendil-works/pi-tui";

export default function queueFollowUp(pi: ExtensionAPI): void {
  pi.registerShortcut(Key.tab, {
    description: "Queue the current prompt until the agent finishes",
    handler: (ctx) => {
      const message = ctx.ui.getEditorText().trim();
      if (!message) return;

      ctx.ui.setEditorText("");

      if (ctx.isIdle()) {
        pi.sendUserMessage(message);
        return;
      }

      pi.sendUserMessage(message, { deliverAs: "followUp" });
      ctx.ui.notify("Follow-up queued", "info");
    },
  });
}
