import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";
import { Effect } from "effect";
import { healthReport } from "../../src/health.ts";

export default function effectHealthExtension(pi: ExtensionAPI): void {
	pi.setLabel("Effect health");

	pi.registerCommand("effect-health", {
		description: "Check that the standalone OMP Effect workspace is loaded",
		handler: (_args, ctx) =>
			Effect.runPromise(
				healthReport(ctx.cwd).pipe(
					Effect.tap((report) =>
						Effect.sync(() => {
							ctx.ui.notify(`${report.message}\nProject: ${report.cwd}`, "info");
						}),
					),
					Effect.asVoid,
				),
			),
	});
}
