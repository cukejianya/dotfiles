/**
 * Compact startup summary for pi.
 *
 * Pairs with `"quietStartup": true` (which hides pi's verbose
 * [Context]/[Skills]/[Extensions]/[Themes] block) by printing a single
 * one-line summary into the transcript at session start / reload:
 *
 *   ✻ 103 skills · 4 extensions · 2 prompts · 5 themes · 2/3 mcp · 12 models
 *
 * Counts:
 *   - models  → available only (ctx.modelRegistry.getAvailable(), i.e. models
 *               with configured auth)
 *   - mcp     → pi-mcp-adapter servers (connected/cached / configured), scanned
 *               from the adapter's config sources + mcp-cache.json
 *   - themes  → exact, from ctx.ui.getAllThemes()
 *   - skills / extensions / prompts → scanned from the standard discovery
 *     directories (see note in README below); approximate but matches the
 *     common global + project layout.
 *
 * Placement: ~/.pi/agent/extensions/startup-summary.ts (auto-discovered).
 */

import { existsSync, readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";

const HOME = process.env.HOME ?? "";
// pi's config/agent directory, honoring the PI_CODING_AGENT_DIR override.
const AGENT_DIR = process.env.PI_CODING_AGENT_DIR || join(HOME, ".pi/agent");

interface Counts {
	skillsEnabled: number;
	skillsTotal: number;
	extensions: number;
	prompts: number;
	themes: number;
	mcpEnabled: number;
	mcpTotal: number;
	modelsAvailable: number;
	modelsTotal: number;
}

/** Disable patterns (!pat / -pat) from the skills setting across scopes. */
function skillDisablePatterns(cwd: string): string[] {
	const out: string[] = [];
	for (const p of [join(AGENT_DIR, "settings.json"), join(cwd, ".pi/settings.json")]) {
		if (!existsSync(p)) continue;
		try {
			const s = JSON.parse(readFileSync(p, "utf8"));
			const arr: unknown[] = Array.isArray(s.skills) ? s.skills : [];
			for (const e of arr) {
				if (typeof e === "string" && (e.startsWith("!") || e.startsWith("-"))) {
					out.push(e.slice(1));
				}
			}
		} catch {
			/* ignore */
		}
	}
	return out;
}

/**
 * Count skill subdirectories (deduped by name) and how many are enabled.
 * A skill is "disabled" if a disable pattern matches its name or path.
 */
function countSkills(cwd: string): { total: number; enabled: number } {
	const roots = [
		join(HOME, ".agents/skills"),
		join(AGENT_DIR, "skills"),
		join(cwd, ".agents/skills"),
		join(cwd, ".pi/skills"),
	];
	const disable = skillDisablePatterns(cwd);
	const isDisabled = (name: string, path: string) =>
		disable.some((pat) => pat === name || path.includes(pat) || name.includes(pat));
	const seen = new Set<string>();
	let total = 0;
	let enabled = 0;
	for (const root of roots) {
		if (!existsSync(root)) continue;
		try {
			for (const entry of readdirSync(root, { withFileTypes: true })) {
				if (!entry.isDirectory() && !entry.isSymbolicLink()) continue;
				const skillPath = join(root, entry.name, "SKILL.md");
				if (!existsSync(skillPath)) continue;
				if (seen.has(entry.name)) continue;
				seen.add(entry.name);
				total++;
				if (!isDisabled(entry.name, skillPath)) enabled++;
			}
		} catch {
			/* ignore unreadable roots */
		}
	}
	return { total, enabled };
}

/** Count loadable extension files: top-level .ts/.js and subdir index files. */
function countExtensionFiles(dir: string): number {
	if (!existsSync(dir)) return 0;
	let n = 0;
	try {
		for (const entry of readdirSync(dir, { withFileTypes: true })) {
			if (entry.isFile() && /\.(ts|js)$/.test(entry.name) && !entry.name.endsWith(".d.ts")) {
				n++;
			} else if (entry.isDirectory()) {
				if (
					existsSync(join(dir, entry.name, "index.ts")) ||
					existsSync(join(dir, entry.name, "index.js"))
				) {
					n++;
				}
			}
		}
	} catch {
		/* ignore */
	}
	return n;
}

/** Count package entries in settings that contribute extensions. */
function countPackageExtensions(): number {
	const path = join(AGENT_DIR, "settings.json");
	if (!existsSync(path)) return 0;
	try {
		const settings = JSON.parse(readFileSync(path, "utf8"));
		const pkgs: unknown[] = Array.isArray(settings.packages) ? settings.packages : [];
		return pkgs.filter((p) => {
			const src = typeof p === "string" ? p : (p as { source?: string })?.source;
			return typeof src === "string" && /^(npm:|git:|https?:|ssh:)/.test(src);
		}).length;
	} catch {
		return 0;
	}
}

function countMarkdown(dir: string): number {
	if (!existsSync(dir)) return 0;
	try {
		return readdirSync(dir).filter((f) => f.endsWith(".md")).length;
	} catch {
		return 0;
	}
}

/** Read the `mcpServers` map keys from a single MCP config file. */
function readMcpServerNames(path: string): string[] {
	if (!existsSync(path)) return [];
	try {
		const obj = JSON.parse(readFileSync(path, "utf8"));
		const servers = obj?.mcpServers ?? obj?.["mcp-servers"];
		return servers && typeof servers === "object" ? Object.keys(servers) : [];
	} catch {
		return [];
	}
}

/**
 * Count MCP servers for the pi-mcp-adapter.
 *   - total     → unique servers configured across the adapter's config sources
 *                 (shared-global, pi-global, shared-project, pi-project)
 *   - enabled   → configured servers that have connected (cached in mcp-cache.json)
 */
function countMcp(cwd: string): { total: number; enabled: number } {
	const configPaths = [
		join(HOME, ".config/mcp/mcp.json"), // shared-global
		join(AGENT_DIR, "mcp.json"), // pi-global
		join(cwd, ".mcp.json"), // shared-project
		join(cwd, ".pi/mcp.json"), // pi-project
	];
	const configured = new Set<string>();
	for (const p of configPaths) {
		for (const name of readMcpServerNames(p)) configured.add(name);
	}

	let enabled = 0;
	const cachePath = join(AGENT_DIR, "mcp-cache.json");
	if (existsSync(cachePath)) {
		try {
			const cache = JSON.parse(readFileSync(cachePath, "utf8"));
			const cached = cache?.servers && typeof cache.servers === "object" ? Object.keys(cache.servers) : [];
			enabled = cached.filter((name) => configured.has(name)).length;
		} catch {
			/* ignore */
		}
	}
	return { total: configured.size, enabled };
}

export default function (pi: ExtensionAPI) {
	// Persistent transcript renderer for the summary line.
	pi.registerMessageRenderer<Counts>("startup-summary", (message, _options, theme) => {
		const c = message.details as Counts | undefined;
		if (!c) return new Text(typeof message.content === "string" ? message.content : "", 0, 0);
		const dot = theme.fg("dim", " · ");
		const part = (n: number, label: string) => theme.fg("muted", `${n} ${label}`);
		const line =
			theme.fg("accent", "✻ ") +
			[
				theme.fg("muted", `${c.skillsEnabled}/${c.skillsTotal} skills`),
				part(c.extensions, "extensions"),
				part(c.prompts, "prompts"),
				part(c.themes, "themes"),
				theme.fg("muted", `${c.mcpEnabled}/${c.mcpTotal} mcp`),
				part(c.modelsAvailable, "models"),
			].join(dot);
		return new Text(line, 0, 0);
	});

	pi.on("session_start", async (event, ctx) => {
		// Only for fresh starts and reloads — not every resume/fork.
		if (event.reason !== "startup" && event.reason !== "reload") return;

		const skills = countSkills(ctx.cwd);
		const mcp = countMcp(ctx.cwd);
		const counts: Counts = {
			skillsEnabled: skills.enabled,
			skillsTotal: skills.total,
			extensions:
				countExtensionFiles(join(AGENT_DIR, "extensions")) +
				countExtensionFiles(join(ctx.cwd, ".pi/extensions")) +
				countPackageExtensions(),
			prompts:
				countMarkdown(join(AGENT_DIR, "prompts")) +
				countMarkdown(join(ctx.cwd, ".pi/prompts")),
			themes: ctx.ui.getAllThemes().length,
			mcpEnabled: mcp.enabled,
			mcpTotal: mcp.total,
			modelsAvailable: ctx.modelRegistry.getAvailable().length,
			modelsTotal: ctx.modelRegistry.getAll().length,
		};

		const plain = `✻ ${counts.skillsEnabled}/${counts.skillsTotal} skills · ${counts.extensions} extensions · ${counts.prompts} prompts · ${counts.themes} themes · ${counts.mcpEnabled}/${counts.mcpTotal} mcp · ${counts.modelsAvailable} models`;

		pi.sendMessage({
			customType: "startup-summary",
			content: plain,
			display: true,
			details: counts,
		});
	});
}
