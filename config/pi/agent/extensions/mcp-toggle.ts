/**
 * MCP server toggle popup for pi.
 *
 * Adds a `/mcp-toggle` command that opens a checkbox popup listing MCP servers
 * discovered across your config sources. Check/uncheck servers, press Enter to
 * save. The enabled set is written to your pi-global MCP config:
 *
 *   ~/.config/pi/agent/mcp.json        (enabled servers; honors PI_CODING_AGENT_DIR)
 *   ~/.config/pi/agent/mcp-safe.json   (parked/disabled servers, so they're never lost)
 *
 * Enabling a server moves its definition into mcp.json; disabling it moves the
 * definition into mcp-safe.json. Both files are read when building the list, so
 * a server you turned off still shows up (unchecked) and can be turned back on.
 *
 * Controls:
 *   ↑/↓ or j/k   move
 *   space/x       toggle server
 *   a             enable all
 *   n             disable all
 *   Enter         save
 *   Esc           cancel
 *
 * Notes:
 *   - "Checked" == present in the pi-global config (loaded in every folder).
 *   - Servers defined in a project/repo `.mcp.json` are also active via that
 *     file; this popup only manages the global config.
 *   - After saving, reconnect MCP (e.g. run the `mcp` tool / restart) so the
 *     pi-mcp-adapter picks up the change.
 *
 * Placement: ~/.config/pi/agent/extensions/mcp-toggle.ts (auto-discovered).
 */

import { existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const HOME = process.env.HOME ?? "";
const AGENT_DIR = process.env.PI_CODING_AGENT_DIR || join(HOME, ".pi/agent");
const PI_GLOBAL_CONFIG = join(AGENT_DIR, "mcp.json");
const PI_SAFE_CONFIG = join(AGENT_DIR, "mcp-safe.json");

type ServerDef = Record<string, unknown>;

interface Candidate {
	name: string;
	def: ServerDef;
	source: string; // where the definition was first found
	enabled: boolean; // present in pi-global config
}

/** Safe JSON read; returns {} on any error. */
function readJson(path: string): Record<string, unknown> {
	if (!existsSync(path)) return {};
	try {
		const obj = JSON.parse(readFileSync(path, "utf8"));
		return obj && typeof obj === "object" ? obj : {};
	} catch {
		return {};
	}
}

function serversOf(obj: Record<string, unknown>): Record<string, ServerDef> {
	const s = (obj.mcpServers ?? obj["mcp-servers"]) as Record<string, ServerDef> | undefined;
	return s && typeof s === "object" ? s : {};
}

/** Walk up from cwd collecting every `.mcp.json` (covers repo-root configs). */
function ancestorProjectConfigs(cwd: string): string[] {
	const paths: string[] = [];
	let dir = cwd;
	// Guard against infinite loop; stop at filesystem root or HOME's parent.
	for (let i = 0; i < 40; i++) {
		paths.push(join(dir, ".mcp.json"));
		paths.push(join(dir, ".pi/mcp.json"));
		const parent = dirname(dir);
		if (parent === dir) break;
		dir = parent;
	}
	return paths;
}

/**
 * Build the candidate list: union of all servers discovered across config
 * sources, each flagged with whether it's currently enabled (in pi-global).
 */
function discover(cwd: string): Candidate[] {
	const enabledServers = serversOf(readJson(PI_GLOBAL_CONFIG));
	const enabledNames = new Set(Object.keys(enabledServers));

	// name -> { def, source }. First writer wins, but prefer pi-global's own def.
	const found = new Map<string, { def: ServerDef; source: string }>();

	const addFrom = (path: string, label: string) => {
		const servers = serversOf(readJson(path));
		for (const [name, def] of Object.entries(servers)) {
			if (!found.has(name)) found.set(name, { def, source: label });
		}
	};

	// pi-global first so enabled defs are authoritative, then parked defs.
	addFrom(PI_GLOBAL_CONFIG, "pi-global");
	addFrom(PI_SAFE_CONFIG, "safe (off)");
	for (const p of ancestorProjectConfigs(cwd)) addFrom(p, "project");
	addFrom(join(HOME, ".config/mcp/mcp.json"), "shared-global");

	const candidates: Candidate[] = [...found.entries()].map(([name, { def, source }]) => ({
		name,
		def,
		source,
		enabled: enabledNames.has(name),
	}));
	candidates.sort((a, b) => a.name.localeCompare(b.name));
	return candidates;
}

/** Split candidates: enabled -> mcp.json, disabled -> mcp-safe.json. */
function writeServers(path: string, defs: Record<string, ServerDef>): void {
	const config = readJson(path);
	config.mcpServers = defs;
	delete (config as Record<string, unknown>)["mcp-servers"];
	mkdirSync(dirname(path), { recursive: true });
	writeFileSync(path, `${JSON.stringify(config, null, 2)}\n`, "utf8");
}

function save(candidates: Candidate[]): { enabled: number; parked: number } {
	const enabledDefs: Record<string, ServerDef> = {};
	const parkedDefs: Record<string, ServerDef> = {};
	for (const c of candidates) {
		if (c.enabled) enabledDefs[c.name] = c.def;
		else parkedDefs[c.name] = c.def;
	}
	writeServers(PI_GLOBAL_CONFIG, enabledDefs);
	writeServers(PI_SAFE_CONFIG, parkedDefs);
	return { enabled: Object.keys(enabledDefs).length, parked: Object.keys(parkedDefs).length };
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand("mcp-toggle", {
		description: "Toggle MCP servers on/off (checkbox popup, writes pi-global mcp.json)",
		handler: async (_args, ctx) => {
			if (ctx.mode !== "tui" || !ctx.hasUI) {
				ctx.ui.notify("mcp-toggle needs the interactive TUI", "warning");
				return;
			}

			const candidates = discover(ctx.cwd);
			if (candidates.length === 0) {
				ctx.ui.notify(
					"No MCP servers found in any .mcp.json. Add servers to a project .mcp.json or ~/.config/pi/agent/mcp.json first.",
					"warning",
				);
				return;
			}

			const saved = await ctx.ui.custom<boolean>((tui, theme, keybindings, done) => {
				let cursor = 0;

				const toggle = () => {
					candidates[cursor].enabled = !candidates[cursor].enabled;
					tui.requestRender();
				};
				const setAll = (v: boolean) => {
					for (const c of candidates) c.enabled = v;
					tui.requestRender();
				};
				const move = (delta: number) => {
					cursor = (cursor + delta + candidates.length) % candidates.length;
					tui.requestRender();
				};

				function render(width: number): string[] {
					const lines: string[] = [];
					const enabledCount = candidates.filter((c) => c.enabled).length;
					lines.push(
						theme.fg("accent", theme.bold("✻ MCP servers ")) +
							theme.fg("muted", `(${enabledCount}/${candidates.length} enabled)`),
					);
					lines.push("");
					for (let i = 0; i < candidates.length; i++) {
						const c = candidates[i];
						const isCur = i === cursor;
						const pointer = isCur ? theme.fg("accent", "> ") : "  ";
						const box = c.enabled ? theme.fg("success", "[x]") : theme.fg("dim", "[ ]");
						const nameText = isCur ? theme.bold(c.name) : c.name;
						const name = c.enabled ? theme.fg("text", nameText) : theme.fg("dim", nameText);
						const src = theme.fg("dim", ` · ${c.source}`);
						lines.push(`${pointer}${box} ${name}${src}`);
					}
					lines.push("");
					lines.push(
						theme.fg(
							"dim",
							"↑↓/jk move • space toggle • a all • n none • Enter save • Esc cancel",
						),
					);
					lines.push(theme.fg("accent", "─".repeat(Math.max(1, Math.min(width, 80)))));
					return lines;
				}

				function handleInput(data: string): void {
					if (data === " " || data === "x") return toggle();
					if (keybindings.matches(data, "tui.select.up") || data === "k") return move(-1);
					if (keybindings.matches(data, "tui.select.down") || data === "j") return move(1);
					if (data === "a") return setAll(true);
					if (data === "n") return setAll(false);
					if (keybindings.matches(data, "tui.select.confirm")) return done(true);
					if (keybindings.matches(data, "tui.select.cancel")) return done(false);
				}

				return { render, invalidate: () => {}, handleInput };
			});

			if (!saved) {
				ctx.ui.notify("MCP toggle cancelled", "info");
				return;
			}

			const { enabled, parked } = save(candidates);
			ctx.ui.notify(
				`Saved: ${enabled} on (mcp.json), ${parked} parked (mcp-safe.json). Reconnect MCP to apply.`,
				"info",
			);
		},
	});
}
