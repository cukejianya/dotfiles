/**
 * Compact rendering for pi — tools, diffs, and thinking.
 *
 * Re-skins pi's built-in tools (read, bash, edit, write, grep, find, ls) with
 * dense, Claude-Code-style rows — but a bit better — and additionally:
 *   - renders a compact, colored diff when an edit row is expanded, and
 *   - shows a compact collapsed-thinking label.
 *
 *   ● Read(src/foo.ts)
 *     ⎿ 42 lines
 *
 *   ● Edit(src/foo.ts)
 *     ⎿ +12 -3            (expand → colored, context-collapsed diff)
 *
 * It ONLY overrides rendering: each tool is created from pi's own factory and
 * spread, so execution, schemas, and result shapes are inherited unchanged.
 * Only `renderCall` / `renderResult` are replaced.
 *
 * Toggle with /compact-view (on|off, default on). `/compact` is a built-in
 * (compaction), so this uses a distinct command name.
 *
 * Placement: ~/.pi/agent/extensions/compact.ts (auto-discovered).
 */

import type { AgentToolResult } from "@earendil-works/pi-agent-core";
import {
	createBashToolDefinition,
	createEditToolDefinition,
	createFindToolDefinition,
	createGrepToolDefinition,
	createLsToolDefinition,
	createReadToolDefinition,
	createWriteToolDefinition,
	type ExtensionAPI,
	getLanguageFromPath,
	highlightCode,
	keyHint,
	type Theme,
	type ToolDefinition,
} from "@earendil-works/pi-coding-agent";
import { type Component, Text } from "@earendil-works/pi-tui";
import type { Static, TSchema } from "typebox";

// Continuation glyph for the result row (Claude-style corner).
const RESULT_GLYPH = "⎿";
// Call-row bullet.
const CALL_GLYPH = "●";
// How many lines of full output to show when a row is expanded.
const EXPANDED_MAX_LINES = 400;
// Max consecutive unchanged context lines to keep in a compact diff.
const DIFF_CONTEXT_LINES = 3;

// ── helpers ──────────────────────────────────────────────────────────────

function relPath(p: string | undefined, cwd: string): string {
	if (!p) return "";
	if (cwd && p.startsWith(cwd + "/")) return p.slice(cwd.length + 1);
	if (cwd && p === cwd) return ".";
	const home = process.env.HOME;
	if (home && p.startsWith(home + "/")) return "~/" + p.slice(home.length + 1);
	return p;
}

function ellipsize(s: string, max: number): string {
	const oneLine = s.replace(/\s+/g, " ").trim();
	return oneLine.length > max ? oneLine.slice(0, max - 1) + "…" : oneLine;
}

/** One piece of a shell command: the operator that joined it, plus its text. */
interface CmdSegment {
	/** Operator preceding this command (null for the first/only one). */
	delim: string | null;
	cmd: string;
}

/**
 * Split a shell command into segments at top-level control operators:
 * `&&`, `||`, `;`, `|`, `|&`, `&` (background), and newlines (→ `;`). Operators
 * inside quotes (`'` `"` backtick), `(…)` subshells, or `${…}` are ignored, as
 * are redirections like `&>` / `>&`. Each segment records the operator that
 * precedes it so the UI can show how the step was joined. Pipelines keep each
 * stage on its own segment.
 */
function splitPipeline(command: string): CmdSegment[] {
	const segs: CmdSegment[] = [];
	let buf = "";
	let delim: string | null = null;
	let quote: string | null = null;
	let paren = 0;
	let brace = 0;
	const push = () => {
		const t = buf.trim();
		if (t.length) segs.push({ delim, cmd: t });
		buf = "";
	};
	for (let i = 0; i < command.length; i++) {
		const ch = command[i];
		const nx = command[i + 1];
		if (quote) {
			buf += ch;
			if (ch === quote && command[i - 1] !== "\\") quote = null;
			continue;
		}
		if (ch === '"' || ch === "'" || ch === "`") {
			quote = ch;
			buf += ch;
			continue;
		}
		if (ch === "(") paren++;
		else if (ch === ")" && paren > 0) paren--;
		else if (ch === "{") brace++;
		else if (ch === "}" && brace > 0) brace--;
		if (paren > 0 || brace > 0) {
			buf += ch;
			continue;
		}
		if (ch === "&" && nx === "&") {
			push();
			delim = "&&";
			i++;
			continue;
		}
		if (ch === "|" && nx === "|") {
			push();
			delim = "||";
			i++;
			continue;
		}
		if (ch === "|" && nx === "&") {
			push();
			delim = "|&";
			i++;
			continue;
		}
		if (ch === "|") {
			push();
			delim = "|";
			continue;
		}
		if (ch === ";" || ch === "\n") {
			push();
			delim = ";";
			continue;
		}
		if (ch === "&") {
			// Background operator — but not the `&>` / `>&` redirections.
			if (nx === ">" || command[i - 1] === ">") {
				buf += ch;
				continue;
			}
			push();
			delim = "&";
			continue;
		}
		buf += ch;
	}
	push();
	return segs;
}

/** Greedy word-wrap to `maxWidth` columns, hard-breaking over-long tokens. */
function wrapText(text: string, maxWidth: number): string[] {
	if (maxWidth <= 0) return [text];
	const out: string[] = [];
	for (const raw of text.split("\n")) {
		let line = raw;
		while (line.length > maxWidth) {
			let br = line.lastIndexOf(" ", maxWidth);
			if (br <= 0) br = maxWidth; // no space → hard break
			out.push(line.slice(0, br));
			line = line.slice(br).replace(/^\s+/, "");
		}
		out.push(line);
	}
	return out.length ? out : [""];
}

/**
 * Width-aware tree renderer for an `&&`/`|`/`;`/`||`/`&` command chain. Each
 * segment is one branch: `├─`/`└─` + delimiter + full command, soft-wrapped
 * with a hanging indent. Wrapped continuation lines keep the tree connected
 * with a `│` guide for non-last items (blank for the last). No truncation.
 */
class BashTreeComponent implements Component {
	constructor(
		private readonly header: string,
		private readonly segs: CmdSegment[],
		private readonly theme: Theme,
	) {}

	render(width: number): string[] {
		const t = this.theme;
		const out: string[] = [this.header];
		const n = this.segs.length;
		this.segs.forEach((seg, i) => {
			const isLast = i === n - 1;
			const branch = isLast ? "  └─ " : "  ├─ "; // 5 visible cols
			const delimText = seg.delim ? seg.delim + " " : "";
			const cmdCol = 5 + delimText.length;
			const avail = Math.max(8, width - cmdCol);
			const wrapped = wrapText(seg.cmd, avail);
			const firstPrefix = t.fg("dim", branch) + (delimText ? t.fg("muted", delimText) : "");
			out.push(firstPrefix + t.fg("dim", wrapped[0] ?? ""));
			for (let k = 1; k < wrapped.length; k++) {
				const gutter = isLast
					? " ".repeat(cmdCol)
					: t.fg("dim", "  │") + " ".repeat(cmdCol - 3);
				out.push(gutter + t.fg("dim", wrapped[k]));
			}
		});
		return out;
	}
}

// Pulse (breathe) the call bullet while a tool is running by cycling through
// dim→bright→dim theme colors. Discrete theme color keys are used (themes don't
// expose raw RGB), which reads as a smooth triangle-wave fade.
const PULSE_KEYS = ["dim", "muted", "accent", "muted"] as const;
const PULSE_MS = 400;

// The pulse is gated STRICTLY by live execution events (tool_execution_start/
// end), never by render/isPartial state. On resume (`pi -c`), pi reconstructs
// history and tool rows briefly render as isPartial=true, but no start events
// fire for them — so `liveTools` stays empty and nothing animates. This is what
// prevents the "flickering with nothing running" bug: render state alone could
// register historical rows that never get a matching tool_execution_end.
//
// A single shared ticker invalidates all live rows on one phase-aligned tick,
// and stops entirely when no tool is executing.
const liveTools = new Set<string>();
const activePulse = new Map<string, () => void>();
let pulseTicker: ReturnType<typeof setInterval> | undefined;

function ensurePulseTicker(): void {
	if (pulseTicker === undefined) {
		pulseTicker = setInterval(() => {
			for (const invalidate of activePulse.values()) invalidate();
		}, PULSE_MS);
	}
}

function removePulse(id: string | undefined): void {
	if (id && activePulse.delete(id) && activePulse.size === 0 && pulseTicker !== undefined) {
		clearInterval(pulseTicker);
		pulseTicker = undefined;
	}
}

/**
 * The `●` call bullet. It breathes only while the tool is genuinely executing
 * in THIS process (its toolCallId is in `liveTools`); otherwise it is a static
 * `accent` `●`. Live rows register their `invalidate` with the shared ticker.
 */
function callGlyph(
	theme: Theme,
	context: {
		toolCallId?: string;
		invalidate?: () => void;
		isPartial?: boolean;
		isError?: boolean;
	},
): string {
	const id = context.toolCallId;
	if (id !== undefined && liveTools.has(id)) {
		if (typeof context.invalidate === "function" && !activePulse.has(id)) {
			activePulse.set(id, context.invalidate);
			ensurePulseTicker();
		}
		const key = PULSE_KEYS[Math.floor(Date.now() / PULSE_MS) % PULSE_KEYS.length];
		return theme.fg(key, CALL_GLYPH) + " ";
	}
	removePulse(id);
	// Not live: pending (no result yet) is neutral; completed rows carry status.
	if (context.isPartial) return theme.fg("accent", CALL_GLYPH) + " ";
	return theme.fg(context.isError ? "error" : "success", CALL_GLYPH) + " ";
}

/** Extract plain text from a tool result's content array. */
function resultText(result: AgentToolResult<unknown>): string {
	let out = "";
	let hasImage = false;
	for (const c of result.content) {
		if (c.type === "text") out += c.text;
		else hasImage = true;
	}
	if (hasImage && !out) return "[image]";
	return out;
}

function countLines(text: string): number {
	if (!text) return 0;
	const trimmed = text.endsWith("\n") ? text.slice(0, -1) : text;
	if (trimmed === "") return 0;
	return trimmed.split("\n").length;
}

/** Count +/- lines in a unified patch (ignoring +++/--- headers). */
function diffStats(patch: string | undefined): { adds: number; dels: number } {
	let adds = 0;
	let dels = 0;
	if (!patch) return { adds, dels };
	for (const line of patch.split("\n")) {
		if (line.startsWith("+") && !line.startsWith("+++")) adds++;
		else if (line.startsWith("-") && !line.startsWith("---")) dels++;
	}
	return { adds, dels };
}

/**
 * Colorize a unified patch into compact themed lines: additions green,
 * deletions red, hunk headers dim; runs of unchanged context are collapsed to
 * a "⋯" marker so only the interesting neighborhood of each change is shown.
 */
function compactDiff(patch: string | undefined, theme: Theme): string[] {
	if (!patch) return [];
	const raw = patch.split("\n");
	// Drop file headers; keep hunks + changes + context.
	const filtered = raw.filter(
		(l) => !l.startsWith("+++") && !l.startsWith("---") && !l.startsWith("diff "),
	);

	// Find indices of changed lines so we can keep a small context window.
	const isChange = (l: string) => l.startsWith("+") || l.startsWith("-");
	const keep = new Array<boolean>(filtered.length).fill(false);
	for (let i = 0; i < filtered.length; i++) {
		if (isChange(filtered[i]) || filtered[i].startsWith("@@")) {
			for (
				let j = Math.max(0, i - DIFF_CONTEXT_LINES);
				j <= Math.min(filtered.length - 1, i + DIFF_CONTEXT_LINES);
				j++
			) {
				keep[j] = true;
			}
		}
	}

	const out: string[] = [];
	let collapsed = false;
	for (let i = 0; i < filtered.length; i++) {
		if (!keep[i]) {
			if (!collapsed) {
				out.push(theme.fg("muted", "⋯"));
				collapsed = true;
			}
			continue;
		}
		collapsed = false;
		const l = filtered[i];
		if (l.startsWith("@@")) out.push(theme.fg("muted", l));
		else if (l.startsWith("+")) out.push(theme.fg("success", l));
		else if (l.startsWith("-")) out.push(theme.fg("error", l));
		else out.push(theme.fg("dim", l));
	}
	return out;
}

// ── generic compact registration ───────────────────────────────────────────

interface CompactConfig<P extends TSchema, D> {
	/** Primary argument shown in the call row, e.g. the path or command. */
	primary: (args: Static<P>, cwd: string) => string;
	/** One-line result summary. Return themed text. */
	summary: (ctx: {
		args: Static<P>;
		result: AgentToolResult<D>;
		text: string;
		isError: boolean;
		theme: Theme;
		cwd: string;
	}) => string;
	/**
	 * Optional custom expanded body (already themed, one entry per line).
	 * Return undefined to fall back to the default raw-text dump.
	 */
	expandedBody?: (ctx: {
		args: Static<P>;
		result: AgentToolResult<D>;
		text: string;
		theme: Theme;
	}) => string[] | undefined;
	/**
	 * Optional full replacement for the call row. Receives the call glyph prefix
	 * (already themed) so the row keeps a consistent `●` bullet. Return undefined
	 * to use the default `● Label(primary)` row.
	 */
	callRow?: (ctx: {
		args: Static<P>;
		theme: Theme;
		context: { executionStarted?: boolean; isPartial?: boolean; isError?: boolean };
		glyph: string;
	}) => Component | undefined;
}

export default function (pi: ExtensionAPI) {
	const cwd = process.cwd();

	// Compact rendering is on by default. When off, we delegate to pi's built-in
	// renderers (captured from the tool factory), restoring full syntax
	// highlighting / diffs rather than a degraded fallback.
	let enabled = true;

	function applyThinkingLabel(
		ui: { setHiddenThinkingLabel(label?: string): void; theme: Theme },
	): void {
		if (enabled) {
			const t = ui.theme;
			ui.setHiddenThinkingLabel(
				t.fg("dim", "💭 thinking ") +
					t.fg("muted", keyHint("app.thinking.toggle", "expand")),
			);
		} else {
			ui.setHiddenThinkingLabel(); // restore default
		}
	}

	function registerCompact<P extends TSchema, D>(
		base: ToolDefinition<P, D>,
		cfg: CompactConfig<P, D>,
	): void {
		const baseRenderCall = base.renderCall;
		const baseRenderResult = base.renderResult;
		pi.registerTool({
			...base,
			// Render our own shell so pi doesn't wrap the row in the default Box
			// (which carries the themed tool background). No box → no background.
			renderShell: "self",
			renderCall(args: Static<P>, theme: Theme, context): Component {
				if (!enabled && baseRenderCall) return baseRenderCall(args, theme, context);
				const glyph = callGlyph(theme, context);
				if (cfg.callRow) {
					const custom = cfg.callRow({ args, theme, context, glyph });
					if (custom) return custom;
				}
				const primary = cfg.primary(args, cwd);
				let line = glyph;
				line += theme.fg("toolTitle", theme.bold(base.label));
				line += theme.fg("muted", "(") + theme.fg("dim", primary) + theme.fg("muted", ")");
				return new Text(line, 0, 0);
			},
			renderResult(
				result: AgentToolResult<D>,
				options: { expanded: boolean; isPartial: boolean },
				theme: Theme,
				context: { isError?: boolean; args?: Static<P> },
			): Component {
				if (!enabled && baseRenderResult) {
					return baseRenderResult(result, options, theme, context as never);
				}
				const glyph = theme.fg("dim", `  ${RESULT_GLYPH} `);

				if (options.isPartial) {
					return new Text(glyph + theme.fg("dim", "…"), 0, 0);
				}

				const text = resultText(result as AgentToolResult<unknown>);
				const args = context.args ?? ({} as Static<P>);
				const isError = context.isError === true;
				const summary = cfg.summary({ args, result, text, isError, theme, cwd });

				let line = glyph + summary;

				if (options.expanded) {
					const custom = cfg.expandedBody?.({ args, result, text, theme });
					const bodyLines = custom ?? text.split("\n").map((l) => theme.fg("dim", l));
					const shown = bodyLines.slice(0, EXPANDED_MAX_LINES);
					const body = shown.map((l) => "    " + l).join("\n");
					if (body) line += "\n" + body;
					if (bodyLines.length > EXPANDED_MAX_LINES) {
						line +=
							"\n" +
							theme.fg("muted", `    … ${bodyLines.length - EXPANDED_MAX_LINES} more lines`);
					}
				} else if (countLines(text) > 1) {
					line += theme.fg("muted", `  ${keyHint("app.tools.expand", "expand")}`);
				}

				return new Text(line, 0, 0);
			},
		});
	}

	// ── read ──────────────────────────────────────────────────────────────
	registerCompact(createReadToolDefinition(cwd), {
		primary: (a, c) => {
			const p = relPath((a as { path?: string }).path, c);
			const off = (a as { offset?: number }).offset;
			return off ? `${p}:${off}` : p;
		},
		summary: ({ result, text, theme }) => {
			const tr = (result.details as { truncation?: { truncated: boolean; totalLines: number } } | undefined)
				?.truncation;
			const shown = countLines(text);
			if (tr?.truncated) {
				return theme.fg("success", `${shown}/${tr.totalLines} lines`) + theme.fg("warning", " (truncated)");
			}
			if (text === "[image]") return theme.fg("success", "image");
			return theme.fg("success", `${shown} ${shown === 1 ? "line" : "lines"}`);
		},
	});

	// ── bash ──────────────────────────────────────────────────────────────
	registerCompact(createBashToolDefinition(cwd), {
		primary: (a) => ellipsize((a as { command?: string }).command ?? "", 60),
		// Always render `bash (N)` + a tree (even for N=1). Each command is a branch
		// with its joining delimiter in front and the FULL command soft-wrapped (no
		// truncation); wrapped lines stay connected via a `│` guide. Status shows via
		// the `●` color (blue running / green success / red fail); command text dim.
		callRow: ({ args, theme, glyph }) => {
			const command = (args as { command?: string }).command ?? "";
			const segs = splitPipeline(command);
			if (segs.length === 0) segs.push({ delim: null, cmd: command });
			const header =
				glyph +
				theme.fg("toolTitle", theme.bold("bash")) +
				" " +
				theme.fg("muted", `(${segs.length})`);
			return new BashTreeComponent(header, segs, theme);
		},
		summary: ({ text, isError, theme }) => {
			if (isError) {
				const firstErr = text.split("\n").find((l) => l.trim().length > 0) ?? "failed";
				return theme.fg("error", ellipsize(firstErr, 80));
			}
			const n = countLines(text);
			if (n === 0) return theme.fg("dim", "(no output)");
			return theme.fg("success", `${n} ${n === 1 ? "line" : "lines"}`);
		},
	});

	// ── edit ──────────────────────────────────────────────────────────────
	registerCompact(createEditToolDefinition(cwd), {
		primary: (a, c) => relPath((a as { path?: string }).path, c),
		summary: ({ result, isError, theme }) => {
			if (isError) return theme.fg("error", "failed");
			const { adds, dels } = diffStats((result.details as { patch?: string } | undefined)?.patch);
			return theme.fg("success", `+${adds}`) + " " + theme.fg("error", `-${dels}`);
		},
		// Expanded: compact, colored, context-collapsed diff instead of raw text.
		expandedBody: ({ result, theme }) =>
			compactDiff((result.details as { patch?: string } | undefined)?.patch, theme),
	});

	// ── write ─────────────────────────────────────────────────────────────
	registerCompact(createWriteToolDefinition(cwd), {
		primary: (a, c) => relPath((a as { path?: string }).path, c),
		summary: ({ args, isError, theme }) => {
			if (isError) return theme.fg("error", "failed");
			const n = countLines((args as { content?: string }).content ?? "");
			return theme.fg("success", `wrote ${n} ${n === 1 ? "line" : "lines"}`);
		},
		// Expanded: show the written content with syntax highlighting.
		expandedBody: ({ args }) => {
			const a = args as { path?: string; content?: string };
			if (!a.content) return undefined;
			const lang = a.path ? getLanguageFromPath(a.path) : undefined;
			return highlightCode(a.content, lang);
		},
	});

	// ── grep ──────────────────────────────────────────────────────────────
	registerCompact(createGrepToolDefinition(cwd), {
		primary: (a) => {
			const g = a as { pattern?: string; glob?: string; path?: string };
			let p = g.pattern ?? "";
			if (g.glob) p += ` ${g.glob}`;
			return ellipsize(p, 50);
		},
		summary: ({ text, isError, theme }) => {
			if (isError) return theme.fg("error", "failed");
			const n = countLines(text);
			return theme.fg("success", `${n} ${n === 1 ? "match" : "matches"}`);
		},
	});

	// ── find ──────────────────────────────────────────────────────────────
	registerCompact(createFindToolDefinition(cwd), {
		primary: (a) => ellipsize((a as { pattern?: string }).pattern ?? "", 50),
		summary: ({ text, isError, theme }) => {
			if (isError) return theme.fg("error", "failed");
			const n = countLines(text);
			return theme.fg("success", `${n} ${n === 1 ? "file" : "files"}`);
		},
	});

	// ── ls ────────────────────────────────────────────────────────────────
	registerCompact(createLsToolDefinition(cwd), {
		primary: (a, c) => relPath((a as { path?: string }).path, c) || ".",
		summary: ({ text, isError, theme }) => {
			if (isError) return theme.fg("error", "failed");
			const n = countLines(text);
			return theme.fg("success", `${n} ${n === 1 ? "entry" : "entries"}`);
		},
	});

	// ── thinking: compact collapsed label ───────────────────────────────────
	pi.on("session_start", async (_event, ctx) => {
		applyThinkingLabel(ctx.ui);
	});

	// Pulse lifecycle is driven by real execution events only.
	pi.on("tool_execution_start", async (event) => {
		const id = (event as { toolCallId?: string }).toolCallId;
		if (id) liveTools.add(id);
	});
	pi.on("tool_execution_end", async (event) => {
		const id = (event as { toolCallId?: string }).toolCallId;
		if (id) {
			liveTools.delete(id);
			removePulse(id);
		}
	});

	// Ensure nothing outlives the session.
	pi.on("session_shutdown", async () => {
		liveTools.clear();
		activePulse.clear();
		if (pulseTicker !== undefined) {
			clearInterval(pulseTicker);
			pulseTicker = undefined;
		}
	});

	// ── toggle command ──────────────────────────────────────────────────────
	pi.registerCommand("compact-view", {
		description: "Toggle compact rendering of tools, diffs, and thinking (on|off, default on)",
		handler: async (args, ctx) => {
			const arg = (args ?? "").trim().toLowerCase();
			if (arg === "on") enabled = true;
			else if (arg === "off") enabled = false;
			else enabled = !enabled; // no arg → toggle
			applyThinkingLabel(ctx.ui);
			ctx.ui.notify(
				`Compact rendering ${enabled ? "on" : "off"} (applies to new rows)`,
				"info",
			);
		},
	});
}
