import { assert, describe, it } from "@effect/vitest";
import { Effect } from "effect";
import { healthReport } from "../src/health.ts";

describe("healthReport", () => {
	it.effect("reports the project and Effect runtime", () =>
		Effect.gen(function* () {
			const report = yield* healthReport("/tmp/example");

			assert.strictEqual(report.cwd, "/tmp/example");
			assert.match(report.message, /Effect v4/);
		}),
	);
});
