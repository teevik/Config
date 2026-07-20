import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Key } from "@earendil-works/pi-tui";

const STATUS_KEY = "prompt-stash";

export default function (pi: ExtensionAPI) {
	let stashedPrompt: string | undefined;

	const updateStatus = (ctx: ExtensionContext) => {
		ctx.ui.setStatus(
			STATUS_KEY,
			stashedPrompt === undefined ? undefined : ctx.ui.theme.fg("accent", "prompt stashed"),
		);
	};

	pi.registerShortcut(Key.ctrl("s"), {
		description: "Stash or swap the current prompt",
		handler: (ctx) => {
			const currentPrompt = ctx.ui.getEditorText();

			if (stashedPrompt === undefined) {
				if (currentPrompt.length === 0) {
					ctx.ui.notify("Nothing to stash", "info");
					return;
				}

				stashedPrompt = currentPrompt;
				ctx.ui.setEditorText("");
				updateStatus(ctx);
				ctx.ui.notify("Prompt stashed — press Ctrl+S to restore it", "info");
				return;
			}

			const promptToRestore = stashedPrompt;
			stashedPrompt = currentPrompt.length > 0 ? currentPrompt : undefined;
			ctx.ui.setEditorText(promptToRestore);
			updateStatus(ctx);
			ctx.ui.notify(
				stashedPrompt === undefined
					? "Stashed prompt restored"
					: "Prompts swapped — press Ctrl+S to switch back",
				"info",
			);
		},
	});
}
