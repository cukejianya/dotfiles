/**
 * Rounded, filled input box for pi.
 *
 * pi's editor draws only a top/bottom horizontal rule (no sides, no corners) and
 * has no interior-background theme key. This extension wraps the active editor
 * (including pi-vim's ModalEditor) and, on each render, draws a rounded closed
 * border box (╭─╮ │ │ ╰─╯) around the input. No background fill, no prompt
 * glyph — just the border.
 *
 * It renders the underlying editor into an inner width (terminal width − 2) and
 * frames it, so all editing / vim behavior is preserved.
 *
 * Toggle with /custom-input (on|off, default on). Tune BORDER_HEX.
 *
 * Placement: ~/.config/pi/agent/extensions/custom-input.ts (auto-discovered).
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

// Border color only (no background fill). A slightly lighter border than bg.
const BORDER_HEX = "#5c6370";

function sgrFg(hex: string): string {
	const m = hex.replace("#", "");
	return `\x1b[38;2;${parseInt(m.slice(0, 2), 16)};${parseInt(m.slice(2, 4), 16)};${parseInt(m.slice(4, 6), 16)}m`;
}

const DEFAULT_FG = sgrFg(BORDER_HEX);
const RESET = "\x1b[0m";

// Green ➜ prompt glyph rendered in the reserved left padding of the input.
const PROMPT = "\x1b[32m\u279c\x1b[39m ";

// Named colors -> ANSI foreground SGR codes (used by /color).
const COLOR_CODES: Record<string, string> = {
	black: "30", red: "31", green: "32", yellow: "33", blue: "34",
	magenta: "35", cyan: "36", white: "37", gray: "90", grey: "90",
	brightred: "91", brightgreen: "92", brightyellow: "93", brightblue: "94",
	brightmagenta: "95", brightcyan: "96", brightwhite: "97",
};

// Segment SGR: ticket bright, title dim. State pill uses the shared accent.
const TICKET_SGR = "\x1b[97m"; // bright white
const DIM_SGR = "\x1b[2m";

// Workflow phases (rename-session states) -> phase color. On a rename that
// carries a state, the phase drives the shared accent (Option A: phase wins).
const PHASE_SGR: Record<string, string> = {
	brainstorm: `\x1b[${COLOR_CODES.yellow}m`,
	plan: `\x1b[${COLOR_CODES.yellow}m`,
	implement: `\x1b[${COLOR_CODES.blue}m`,
	"code review": `\x1b[${COLOR_CODES.blue}m`,
	pr: `\x1b[${COLOR_CODES.green}m`,
	review: `\x1b[${COLOR_CODES.green}m`,
	merge: `\x1b[${COLOR_CODES.green}m`,
};

// Shared, mutable UI state (single extension instance).
// accentColor drives BOTH the border and the state pill, so they can never
// disagree. sessionName is the raw name from pi; it's parsed at render time.
let accentColor = DEFAULT_FG;
let sessionName = "";

interface ParsedName {
	ticket?: string;
	state?: string; // canonical casing when it matches a known phase
	title?: string;
}

/** Parse `[TICKET] State - title` with every part optional. */
function parseName(raw: string): ParsedName | null {
	let s = raw.trim();
	if (!s) return null;
	const out: ParsedName = {};

	const ticketMatch = s.match(/^\[([^\]]+)\]\s*/);
	if (ticketMatch) {
		out.ticket = ticketMatch[1].trim();
		s = s.slice(ticketMatch[0].length);
		// Tolerate a stateless "[TICKET] - title" form left as "- title".
		s = s.replace(/^-\s+/, "");
	}

	// Split on the first " - ": left may be a known State, right is the title.
	const sep = s.indexOf(" - ");
	if (sep >= 0) {
		const left = s.slice(0, sep).trim();
		const right = s.slice(sep + 3).trim();
		if (left && PHASE_SGR[left.toLowerCase()]) {
			out.state = left;
			out.title = right || undefined;
		} else if (!left) {
			out.title = right || undefined; // "- title" form
		} else {
			out.title = s.trim() || undefined; // unknown left, keep whole remainder
		}
	} else {
		out.title = s.trim() || undefined;
	}

	if (!out.ticket && !out.state && !out.title) return null;
	return out;
}

/** Fit a segment to exactly `w` visible columns (no background). */
function fill(s: string, w: number): string {
	const vis = visibleWidth(s);
	return vis < w ? s + " ".repeat(w - vis) : vis > w ? truncateToWidth(s, w, "") : s;
}

/** A border piece (corner / side / rule) painted with the shared accent. */
const piece = (s: string): string => accentColor + s + RESET;

/**
 * Build the embedded label (ticket + state pill + title), fitted to `budget`
 * visible cols. Title is truncated first so ticket/state stay intact. Returns
 * the painted string plus its visible width.
 */
function buildLabel(parsed: ParsedName, budget: number): { painted: string; width: number } {
	const parts: string[] = [];
	if (parsed.ticket) parts.push(parsed.ticket);
	if (parsed.state) parts.push(`\u2039 ${parsed.state} \u203a`);
	let title = parsed.title ?? "";

	// Reserve room for a leading + trailing space and the non-title parts.
	const fixedPlain = ` ${parts.join(" ")} `;
	const fixedW = visibleWidth(fixedPlain);
	if (title) {
		const titleBudget = budget - fixedW - (parts.length ? 1 : 0);
		if (titleBudget <= 0) title = "";
		else if (visibleWidth(title) > titleBudget) title = truncateToWidth(title, titleBudget, "\u2026");
	}

	// Paint each present segment.
	const painted: string[] = [];
	if (parsed.ticket) painted.push(TICKET_SGR + parsed.ticket + RESET);
	if (parsed.state) painted.push(accentColor + `\u2039 ${parsed.state} \u203a` + RESET);
	if (title) painted.push(DIM_SGR + title + RESET);
	const body = ` ${painted.join(" ")} `;

	const clamped = visibleWidth(body) > budget ? truncateToWidth(body, budget, "") + RESET : body;
	return { painted: clamped, width: visibleWidth(clamped) };
}

/** Build the top border rule, embedding the parsed session name (if any). */
function topBorder(inner: number): string {
	const parsed = parseName(sessionName);
	if (!parsed) return piece("\u256d" + "\u2500".repeat(inner) + "\u256e");
	const leftLen = 2;
	const rightMin = 2;
	const budget = Math.max(0, inner - leftLen - rightMin);
	const { painted, width } = buildLabel(parsed, budget);
	const rightLen = Math.max(rightMin, inner - leftLen - width);
	return (
		piece("\u256d" + "\u2500".repeat(leftLen)) +
		painted +
		piece("\u2500".repeat(rightLen) + "\u256e")
	);
}

/** Update the shared accent from a rename: phase wins when a state is present. */
function applyPhaseColor(name: string | undefined): void {
	sessionName = (name ?? "").trim();
	const parsed = parseName(sessionName);
	const phase = parsed?.state ? PHASE_SGR[parsed.state.toLowerCase()] : undefined;
	if (phase) accentColor = phase;
}

export default function (pi: ExtensionAPI) {
	let enabled = true;
	let activeTui: { requestRender(): void } | undefined;

	// On rename, phase-derived color wins (Option A): a manual /color tint lasts
	// only until the next state change.
	pi.on("session_info_changed", async (event) => {
		applyPhaseColor((event as { name?: string }).name);
		activeTui?.requestRender();
	});

	const wrapEditor = (ctx: {
		ui: { getEditorComponent: () => unknown; setEditorComponent: (f: unknown) => void };
	}) => {
		const previous = ctx.ui.getEditorComponent() as
			| ((tui: unknown, theme: unknown, kb: unknown) => { render: (w: number) => string[] })
			| undefined;
		if (!previous) return;
		if ((previous as { __boxWrapped?: boolean }).__boxWrapped) return;

		const factory = (tui: unknown, theme: unknown, kb: unknown) => {
			activeTui = tui as { requestRender(): void };
			const base = previous(tui, theme, kb);
			const orig = base.render.bind(base);
			base.render = (width: number): string[] => {
				if (!enabled || width < 6) return orig(width);
				const inner = width - 2;
				const rendered = orig(inner);
				if (rendered.length === 0) return rendered;

				const lines = [...rendered];
				// Defensive: keep any trailing blank spacer lines outside the box.
				const trailing: string[] = [];
				while (lines.length > 1 && lines[lines.length - 1].trim() === "") {
					trailing.unshift(lines.pop() as string);
				}

				// Drop the editor's own top rule; we draw our own.
				lines.shift();
				// Drop the editor's own bottom rule (pi-vim no longer strips it).
				if (lines.length > 1) lines.pop();
				// Render the ➜ prompt in the reserved left padding of the first
				// input line (requires editorPaddingX >= 2).
				if (lines.length > 0 && lines[0].startsWith("  ")) {
					lines[0] = PROMPT + lines[0].slice(2);
				}

				const out: string[] = [];
				out.push(topBorder(inner));
				for (const line of lines) out.push(piece("│") + fill(line, inner) + piece("│"));
				out.push(piece("╰" + "─".repeat(inner) + "╯"));
				out.push(""); // spacer between input box and footer
				out.push(...trailing);
				return out;
			};
			return base;
		};
		(factory as { __boxWrapped?: boolean }).__boxWrapped = true;
		ctx.ui.setEditorComponent(factory);
	};

	// Defer so editor-providing extensions (pi-vim) register first.
	pi.on("session_start", (_event, ctx) => {
		if (ctx.mode !== "tui") return;
		applyPhaseColor(pi.getSessionName?.());
		setTimeout(() => wrapEditor(ctx as never), 0);
	});

	pi.registerCommand("custom-input", {
		description: "Toggle the rounded, filled input box (on|off, default on)",
		handler: async (args, ctx) => {
			const arg = (args ?? "").trim().toLowerCase();
			if (arg === "on") enabled = true;
			else if (arg === "off") enabled = false;
			else enabled = !enabled;
			wrapEditor(ctx as never);
			ctx.ui.setEditorText(ctx.ui.getEditorText?.() ?? "");
			ctx.ui.notify(`Input box ${enabled ? "on" : "off"}`, "info");
		},
	});

	// /color <name|reset> — manually set the shared accent (border + state pill).
	// A manual tint lasts until the next rename that carries a workflow state.
	pi.registerCommand("color", {
		description: `Set input border + state color: ${Object.keys(COLOR_CODES).join(", ")}, or reset`,
		handler: async (args, ctx) => {
			const arg = (args ?? "").trim().toLowerCase();
			if (arg === "" || arg === "reset" || arg === "default") {
				accentColor = DEFAULT_FG;
				activeTui?.requestRender();
				ctx.ui.notify("Input color reset", "info");
				return;
			}
			const code = COLOR_CODES[arg];
			if (!code) {
				ctx.ui.notify(
					`Unknown color "${arg}". Try: ${Object.keys(COLOR_CODES).join(", ")}, reset`,
					"error",
				);
				return;
			}
			accentColor = `\x1b[${code}m`;
			activeTui?.requestRender();
			ctx.ui.notify(`Input color set to ${arg}`, "info");
		},
	});
}
