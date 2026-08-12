import { Effect } from "effect";

export interface HealthReport {
	readonly cwd: string;
	readonly message: string;
}

export const healthReport = (cwd: string): Effect.Effect<HealthReport> =>
	Effect.succeed({
		cwd,
		message: "OMP extensions are running with Effect v4.",
	});
