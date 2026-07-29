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

// Shared slots. This extension now owns publishing + reading them.
const SESSION_NAME_KEY = Symbol.for("pi:session-name");
const SESSION_NAME_COLOR_KEY = Symbol.for("pi:session-name-color");
const INPUT_BORDER_COLOR_KEY = Symbol.for("pi:input-border-color");

/** Current border SGR: whatever /color set, else the default. */
function currentFg(): string {
	const c = (globalThis as Record<symbol, unknown>)[INPUT_BORDER_COLOR_KEY];
	return typeof c === "string" && c ? c : DEFAULT_FG;
}

/** Fit a segment to exactly `w` visible columns (no background). */
function fill(s: string, w: number): string {
	const vis = visibleWidth(s);
	return vis < w ? s + " ".repeat(w - vis) : vis > w ? truncateToWidth(s, w, "") : s;
}

/** A border piece (corner / side / rule) painted with the current border color. */
const piece = (s: string): string => currentFg() + s + RESET;

/** Paint the session-name label with its own color (falls back to border color). */
function paintName(s: string): string {
	const c = (globalThis as Record<symbol, unknown>)[SESSION_NAME_COLOR_KEY];
	return typeof c === "string" && c ? c + s + RESET : piece(s);
}

/** Build the top border rule, embedding the session name (if any). */
function topBorder(inner: number): string {
	const raw = (globalThis as Record<symbol, unknown>)[SESSION_NAME_KEY];
	const name = typeof raw === "string" ? raw.trim() : "";
	if (!name) return piece("\u256d" + "\u2500".repeat(inner) + "\u256e");
	const label = ` ${name} `;
	const leftLen = 2;
	const rightLen = Math.max(0, inner - leftLen - visibleWidth(label));
	return (
		piece("\u256d" + "\u2500".repeat(leftLen)) +
		paintName(label) +
		piece("\u2500".repeat(rightLen) + "\u256e")
	);
}

export default function (pi: ExtensionAPI) {
	let enabled = true;
	let activeTui: { requestRender(): void } | undefined;
	const g = globalThis as Record<symbol, unknown>;

	// This extension now owns publishing the session name for the input border.
	function publishSessionName(name: string | undefined) {
		g[SESSION_NAME_KEY] = name ?? "";
		activeTui?.requestRender();
	}
	pi.on("session_info_changed", async (event) => {
		publishSessionName((event as { name?: string }).name);
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
		publishSessionName(pi.getSessionName?.());
		if (g[SESSION_NAME_COLOR_KEY] === undefined) {
			g[SESSION_NAME_COLOR_KEY] = "\x1b[2m"; // dim
		}
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

	// /color <name|reset> — set the input border + session-name color.
	pi.registerCommand("color", {
		description: `Set input border color: ${Object.keys(COLOR_CODES).join(", ")}, or reset`,
		handler: async (args, ctx) => {
			const arg = (args ?? "").trim().toLowerCase();
			if (arg === "" || arg === "reset" || arg === "default") {
				g[SESSION_NAME_COLOR_KEY] = "";
				g[INPUT_BORDER_COLOR_KEY] = "";
				activeTui?.requestRender();
				ctx.ui.notify("Input border color reset", "info");
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
			g[SESSION_NAME_COLOR_KEY] = `\x1b[${code}m`;
			g[INPUT_BORDER_COLOR_KEY] = `\x1b[${code}m`;
			activeTui?.requestRender();
			ctx.ui.notify(`Input border color set to ${arg}`, "info");
		},
	});
}
