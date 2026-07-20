import { mkdir, readFile, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import {
	CONFIG_DIR_NAME,
	type ExtensionAPI,
	type ExtensionContext,
} from "@earendil-works/pi-coding-agent";

const SETTINGS_KEY = "pi-codex-fast";
const STATE_EVENT = "codex-fast:state";
const PRIORITY_MODELS = new Set([
	"openai-codex/gpt-5.4",
	"openai-codex/gpt-5.5",
	"openai-codex/gpt-5.6-sol",
	"openai-codex/gpt-5.6-terra",
	"openai-codex/gpt-5.6-luna",
]);

type Settings = Record<string, unknown>;

function isRecord(value: unknown): value is Settings {
	return typeof value === "object" && value !== null && !Array.isArray(value);
}

function modelName(ctx: ExtensionContext): string | undefined {
	return ctx.model ? `${ctx.model.provider}/${ctx.model.id}` : undefined;
}

function globalSettingsPath(): string {
	return join(
		process.env.PI_CODING_AGENT_DIR ?? join(homedir(), CONFIG_DIR_NAME, "agent"),
		"settings.json",
	);
}

function projectSettingsPath(cwd: string): string {
	return join(cwd, CONFIG_DIR_NAME, "settings.json");
}

async function readSettings(path: string): Promise<Settings> {
	try {
		const value: unknown = JSON.parse(await readFile(path, "utf8"));
		return isRecord(value) ? value : {};
	} catch (error) {
		if (isRecord(error) && error.code === "ENOENT") return {};
		throw error;
	}
}

function mergeSettings(base: Settings, override: Settings): Settings {
	const merged = { ...base };
	for (const [key, overrideValue] of Object.entries(override)) {
		const baseValue = merged[key];
		merged[key] =
			isRecord(baseValue) && isRecord(overrideValue)
				? mergeSettings(baseValue, overrideValue)
				: overrideValue;
	}
	return merged;
}

async function loadEnabled(cwd: string): Promise<boolean> {
	const settings = mergeSettings(
		await readSettings(globalSettingsPath()),
		await readSettings(projectSettingsPath(cwd)),
	);
	const extensionSettings = settings[SETTINGS_KEY];
	return isRecord(extensionSettings) && extensionSettings.enabled === true;
}

async function saveEnabled(enabled: boolean): Promise<void> {
	const path = globalSettingsPath();
	const settings = await readSettings(path);
	const previous = settings[SETTINGS_KEY];
	settings[SETTINGS_KEY] = {
		...(isRecord(previous) ? previous : {}),
		enabled,
	};

	await mkdir(dirname(path), { recursive: true });
	await writeFile(path, `${JSON.stringify(settings, null, 2)}\n`);
}

export default function codexFast(pi: ExtensionAPI): void {
	let enabled = false;
	let writeQueue: Promise<void> = Promise.resolve();

	function emitState(ctx: ExtensionContext): void {
		const model = modelName(ctx);
		pi.events.emit(STATE_EVENT, {
			enabled,
			active: enabled && model !== undefined && PRIORITY_MODELS.has(model),
			model,
		});
	}

	function persist(enabledValue: boolean): void {
		writeQueue = writeQueue
			.catch(() => undefined)
			.then(() => saveEnabled(enabledValue));
		void writeQueue.catch((error) => {
			console.error("codex-fast: failed to save settings", error);
		});
	}

	pi.registerFlag("fast", {
		description: "Start with Codex priority service enabled",
		type: "boolean",
		default: false,
	});

	pi.registerCommand("codex-fast", {
		description: "Toggle Codex priority service",
		handler: async (_args, ctx) => {
			enabled = !enabled;
			emitState(ctx);
			persist(enabled);
		},
	});

	pi.on("session_start", async (_event, ctx) => {
		try {
			enabled = await loadEnabled(ctx.cwd);
		} catch (error) {
			enabled = false;
			console.error("codex-fast: failed to load settings", error);
		}

		if (pi.getFlag("fast") === true) enabled = true;
		emitState(ctx);
	});

	pi.on("model_select", async (_event, ctx) => {
		emitState(ctx);
	});

	pi.on("before_provider_request", (event, ctx) => {
		const model = modelName(ctx);
		if (
			!enabled ||
			model === undefined ||
			!PRIORITY_MODELS.has(model) ||
			!isRecord(event.payload)
		) {
			return;
		}

		return { ...event.payload, service_tier: "priority" };
	});
}
