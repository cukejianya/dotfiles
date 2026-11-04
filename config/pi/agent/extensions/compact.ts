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
import { type Component, Text, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import type { Static, TSchema } from "typebox";

/** Renders zero lines. Used by `hidden` mode to drop a tool row entirely. */
const EMPTY: Component = { render: () => [], invalidate: () => {} };

// Continuation glyph for the result row (Claude-style corner).
const RESULT_GLYPH = "⎿";
// Call-row bullet, per outcome. All are width 1, so rows stay aligned.
const CALL_GLYPH = "●"; // running / pending
const FAIL_GLYPH = "✗";
const OK_GLYPH = "✓";
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
 *
 * A heredoc body is raw data, not shell syntax, so it is copied verbatim into
 * its segment. Without this a `python3 - <<'EOF'` block would shred into one
 * junk branch per body line, because every newline reads as a `;` operator.
 */
function splitPipeline(command: string): CmdSegment[] {
	const segs: CmdSegment[] = [];
	let buf = "";
	let delim: string | null = null;
	let quote: string | null = null;
	let paren = 0;
	let brace = 0;
	// Heredocs opened on the current line; their bodies start at the next newline.
	let pending: { word: string; indent: boolean }[] = [];
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
		// `<<WORD` / `<<-WORD` / `<<'WORD'` opens a heredoc. `<<<` is a herestring.
		if (ch === "<" && nx === "<" && command[i + 2] !== "<") {
			const open = /^<<(-?)\s*(['"]?)([A-Za-z_][A-Za-z0-9_]*)\2/.exec(command.slice(i));
			if (open) {
				pending.push({ word: open[3], indent: open[1] === "-" });
				buf += open[0];
				i += open[0].length - 1;
				continue;
			}
		}
		if (ch === "\n" && pending.length) {
			// Swallow every open body, in order, through its terminator line.
			let j = i + 1;
			for (const hd of pending) {
				const end = new RegExp(`^${hd.indent ? "[ \\t]*" : ""}${hd.word}[ \\t]*$`, "m").exec(
					command.slice(j),
				);
				j = end ? j + end.index + end[0].length : command.length;
			}
			buf += command.slice(i, j);
			i = j - 1;
			pending = [];
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

/**
 * Greedy word-wrap to `maxWidth` visible columns, hard-breaking over-long
 * tokens. Width is measured with `visibleWidth`/`truncateToWidth` so wide
 * glyphs (emoji, CJK) that occupy two terminal cells are counted correctly —
 * a plain `.length` count would under-measure and overflow the terminal,
 * which crashes pi's render-time width assertion.
 */
function wrapText(text: string, maxWidth: number): string[] {
	if (maxWidth <= 0) return [text];
	const out: string[] = [];
	for (const raw of text.split("\n")) {
		let line = raw;
		while (visibleWidth(line) > maxWidth) {
			// Largest prefix (in code units) that fits within maxWidth columns.
			const fitted = truncateToWidth(line, maxWidth, "");
			let br = fitted.length;
			// Prefer a soft break at the last space inside the fitted prefix.
			const sp = line.lastIndexOf(" ", br - 1);
			if (sp > 0) br = sp;
			if (br <= 0) br = fitted.length || 1; // guarantee forward progress
			out.push(line.slice(0, br));
			line = line.slice(br).replace(/^\s+/, "");
		}
		out.push(line);
	}
	return out.length ? out : [""];
}

/**
 * Match a segment that ends in a heredoc. Groups: [1] command before the
 * opener, [2] opener token, [4] delimiter word, [5] rest of the opening line,
 * [6] body, [7] terminator line. The opener is captured on its own so the
 * collapsed row can swap `<<'EOF'` for a `<< python(12)` label.
 */
const HEREDOC_RE =
	/^([\s\S]*?)(<<-?\s*(['"]?)([A-Za-z_][A-Za-z0-9_]*)\3)([^\n]*)\n([\s\S]*?)\n?([ \t]*\4[ \t]*)$/;

// Delimiter word -> language, for the `<<'PY'` / `<<SQL` convention.
const HEREDOC_WORD_LANGS: Record<string, string> = {
	py: "python", python: "python", js: "javascript", ts: "typescript",
	sql: "sql", json: "json", yaml: "yaml", yml: "yaml", toml: "toml",
	sh: "bash", bash: "bash", html: "html", css: "css", md: "markdown",
	rb: "ruby", ruby: "ruby", go: "go", rs: "rust",
};

// Interpreter -> language, for the plain `<<'EOF'` case.
const INTERPRETER_LANGS: Record<string, string> = {
	python: "python", python3: "python", node: "javascript", bun: "typescript",
	deno: "typescript", jq: "json", sh: "bash", bash: "bash", zsh: "bash",
	psql: "sql", sqlite3: "sql", mysql: "sql", perl: "perl", ruby: "ruby",
	awk: "awk", gawk: "awk",
};

/**
 * Language for a heredoc body. The delimiter word wins when it names a language
 * (`<<'PY'`), otherwise the interpreter that opens the heredoc decides. Returns
 * undefined for an opaque body (`cat <<'EOF' > file`), which renders unstyled.
 */
function heredocLang(head: string, word: string): string | undefined {
	const byWord = HEREDOC_WORD_LANGS[word.toLowerCase()];
	if (byWord) return byWord;
	for (const token of head.split(/[\s|;()]+/)) {
		const base = token.split("/").pop();
		if (base && INTERPRETER_LANGS[base]) return INTERPRETER_LANGS[base];
	}
	return undefined;
}

/**
 * Width-aware tree renderer for an `&&`/`|`/`;`/`||`/`&` command chain. Each
 * segment is one branch: `├─`/`└─` + delimiter (not `;`) + command, soft-wrapped
 * with a hanging indent. Wrapped continuation lines keep the tree connected
 * with a `│` guide for non-last items (blank for the last). No truncation.
 *
 * A heredoc collapses to a `<< python(12)` label on the opening line. The body
 * appears, highlighted in its own language, only when the row is expanded.
 */
class BashTreeComponent implements Component {
	constructor(
		private readonly header: string,
		private readonly segs: CmdSegment[],
		private readonly theme: Theme,
		private readonly expanded: boolean,
	) {}

	// Stateless: nothing is cached, so there is nothing to drop.
	invalidate(): void {}

	render(width: number): string[] {
		const t = this.theme;
		const out: string[] = [this.header];
		const n = this.segs.length;
		this.segs.forEach((seg, i) => {
			const isLast = i === n - 1;
			const branch = isLast ? "  └─ " : "  ├─ "; // 5 visible cols
			// `;` carries no meaning once the chain is one branch per line, so the
			// branch starts at the command. `&&`/`||`/`|`/`&` still show.
			const delimText = seg.delim && seg.delim !== ";" ? seg.delim + " " : "";
			const cmdCol = 5 + delimText.length;
			const avail = Math.max(8, width - cmdCol);
			const gutter = isLast
				? " ".repeat(cmdCol)
				: t.fg("dim", "  │") + " ".repeat(cmdCol - 3);
			// Only the command text wraps. A heredoc body is data: it is never
			// wrapped, and it is hidden until the row is expanded.
			const hd = HEREDOC_RE.exec(seg.cmd);
			const wrapped = wrapText(hd ? hd[1].trimEnd() : seg.cmd, avail);
			const firstPrefix = t.fg("dim", branch) + (delimText ? t.fg("muted", delimText) : "");
			out.push(firstPrefix + t.fg("dim", wrapped[0] ?? ""));
			for (let k = 1; k < wrapped.length; k++) {
				out.push(gutter + t.fg("dim", wrapped[k]));
			}
			if (!hd) return;

			const lang = heredocLang(hd[1], hd[4]);
			const body = hd[6] === "" ? [] : hd[6].split("\n");
			// `<< python(12)`: the language reads as text, the line count is dim.
			out[out.length - 1] +=
				t.fg("muted", " << ") +
				t.fg("text", lang ?? hd[4].toLowerCase()) +
				t.fg("dim", `(${body.length})`) +
				t.fg("dim", hd[5]);
			if (!this.expanded) return;

			// Highlighted lines carry ANSI, so they are never re-wrapped (slicing
			// would cut an escape in half). The width guard below truncates them.
			if (body.length) {
				for (const line of highlightCode(hd[6], lang)) out.push(gutter + line);
			}
			out.push(gutter + t.fg("dim", hd[7].trim()));
		});
		// Final defensive guard: never emit a line wider than the terminal. The
		// unwrapped `header`, the `avail` min-clamp on very narrow terminals, and
		// resize races between wrap-time and paint-time can each otherwise produce
		// an over-width line, which trips pi's render-time width assertion and
		// crashes the TUI. truncateToWidth is ANSI/width aware.
		return out.map((l) => truncateToWidth(l, width, "…"));
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
	if (context.isError) return theme.fg("error", FAIL_GLYPH) + " ";
	return theme.fg("success", OK_GLYPH) + " ";
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
		context: {
			executionStarted?: boolean;
			isPartial?: boolean;
			isError?: boolean;
			/** Whether the row is expanded. Also drives the result view. */
			expanded?: boolean;
		};
		glyph: string;
	}) => Component | undefined;
}

export default function (pi: ExtensionAPI) {
	const cwd = process.cwd();

	// Compact rendering is on by default. When off, we delegate to pi's built-in
	// renderers (captured from the tool factory), restoring full syntax
	// highlighting / diffs rather than a degraded fallback.
	let enabled = true;
	// Start with tool rows hidden. Ctrl+O reveals collapsed rows, then expanded rows.
	let hidden = true;

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
				if (enabled && hidden) return EMPTY;
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
				if (enabled && hidden) return EMPTY;
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
		// the glyph (blue `●` running / green `✓` success / red `✗` fail); text dim.
		callRow: ({ args, theme, glyph, context }) => {
			const command = (args as { command?: string }).command ?? "";
			const segs = splitPipeline(command);
			if (segs.length === 0) segs.push({ delim: null, cmd: command });
			const header =
				glyph +
				theme.fg("toolTitle", theme.bold("bash")) +
				" " +
				theme.fg("muted", `(${segs.length})`);
			return new BashTreeComponent(header, segs, theme, context.expanded === true);
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

	// ── ctrl+o: cycle the view ──────────────────────────────────────────────
	// pi binds ctrl+o to `app.tools.expand` and reserves that id against
	// extension shortcuts, so `keybindings.json` unbinds it and this handler owns
	// the key. Expansion itself still goes through pi, via setToolsExpanded().
	pi.registerShortcut("ctrl+o", {
		description: "Cycle tool rows: hidden, collapsed, expanded",
		handler: async (ctx) => {
			const ui = ctx.ui;
			if (!enabled) {
				// Compact off: behave exactly like the built-in toggle.
				ui.setToolsExpanded(!ui.getToolsExpanded());
				return;
			}
			// Every branch calls setToolsExpanded, because that is what repaints the
			// existing rows. Without it a `hidden` flip would only affect new rows.
			if (hidden) {
				hidden = false;
				ui.setToolsExpanded(false);
			} else if (!ui.getToolsExpanded()) {
				ui.setToolsExpanded(true);
			} else {
				hidden = true;
				ui.setToolsExpanded(false);
				// setToolsExpanded already announced "Tool output: collapsed". notify()
				// writes to that same status line and reuses the node when it is still
				// last, so this corrects the word in place instead of adding a line.
				ui.notify("Tool output: hidden", "info");
			}
		},
	});

	// ── toggle command ──────────────────────────────────────────────────────
	pi.registerCommand("compact-view", {
		description: "Toggle compact rendering of tools, diffs, and thinking (on|off, default on)",
		handler: async (args, ctx) => {
			const arg = (args ?? "").trim().toLowerCase();
			if (arg === "on") enabled = true;
			else if (arg === "off") enabled = false;
			else enabled = !enabled; // no arg → toggle
			if (!enabled) hidden = false; // pi's own rows are never hidden
			applyThinkingLabel(ctx.ui);
			ctx.ui.notify(
				`Compact rendering ${enabled ? "on" : "off"} (applies to new rows)`,
				"info",
			);
		},
	});
}

// ── self-check ────────────────────────────────────────────────────────────
// Runs only when this file is executed directly, never when pi imports it:
//   cd /opt/homebrew/lib/node_modules && bun ~/.config/pi/agent/extensions/compact.ts
if (import.meta.main) {
	const { strictEqual: eq, deepStrictEqual: deq } = await import("node:assert");

	// A heredoc body stays inside one segment; its newlines are not operators.
	const hd = splitPipeline("cd /tmp\npython3 - <<'EOF'\nx = 1; y = 2\nprint(x)\nEOF\necho done");
	deq(hd.map((s) => s.delim), [null, ";", ";"]);
	eq(hd[1].cmd.split("\n").length, 4); // head + 2 body + terminator
	eq(hd[2].cmd, "echo done");

	// `<<-` allows an indented terminator; `<<<` is a herestring, not a heredoc.
	eq(splitPipeline("cat <<-END\n\tbody\n\tEND\nls").length, 2);
	deq(splitPipeline("grep x <<< $var").map((s) => s.cmd), ["grep x <<< $var"]);

	// Ordinary splitting is unchanged.
	deq(splitPipeline("a && b | c ; d").map((s) => s.delim), [null, "&&", "|", ";"]);

	// The renderer's head / opener / body / terminator split.
	const m = HEREDOC_RE.exec(hd[1].cmd);
	eq(m?.[1], "python3 - ");
	eq(m?.[2], "<<'EOF'");
	eq(m?.[4], "EOF");
	eq(m?.[6], "x = 1; y = 2\nprint(x)");
	eq(m?.[7], "EOF");

	// The opener is captured apart from the tail, so the tail survives the swap
	// to a `<< lang(n)` label.
	eq(HEREDOC_RE.exec("cat <<'TS' > out.ts\nlet a = 1\nTS")?.[5], " > out.ts");

	// Language detection: delimiter word first, then interpreter, else unstyled.
	eq(heredocLang("python3 - ", "EOF"), "python");
	eq(heredocLang("cat ", "SQL"), "sql");
	eq(heredocLang("cat ", "EOF"), undefined);


	// Collapsed row: the body is hidden behind a `<< lang(n)` label.
	const plain = { fg: (_k: string, v: string) => v, bold: (v: string) => v } as unknown as Theme;
	const rows = new BashTreeComponent("bash (1)", [{ delim: null, cmd: "cat <<'TS' > out.ts\nlet a = 1\nlet b = 2\nTS" }], plain, false).render(80);
	deq(rows, ["bash (1)", "  \u2514\u2500 cat << typescript(2) > out.ts"]);

	console.log("compact.ts self-check: ok");
}
