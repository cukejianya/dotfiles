/**
 * Generic checklist popup for pi.
 *
 * Two entry points:
 *
 *  1. `/checklist` command — you drive it.
 *       /checklist apples, bananas, cherries
 *       /checklist
 *         one
 *         two
 *         three
 *     Items are split on newlines, or on commas if it's all one line.
 *     Prefix an item with "[x] " or "* " to pre-check it.
 *     Your selection is sent back into the conversation so the agent can act
 *     on it (download, install, configure, …).
 *
 *  2. `checklist` tool — the agent drives it.
 *     The LLM calls it with { title?, items[], preselected?[] }, you check the
 *     ones you want, and the chosen items are returned in the tool result.
 *
 * Popup controls:
 *   ↑/↓            move          space        toggle current
 *   type           filter        Backspace    edit filter
 *   Ctrl-A         check all (filtered)        Ctrl-D  uncheck all (filtered)
 *   Enter          confirm       Esc          clear filter, or cancel
 *
 * Placement: ~/.config/pi/agent/extensions/checklist.ts (auto-discovered).
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Text, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { Type } from "typebox";

const MAX_VISIBLE = 15;

interface Item {
	label: string;
	checked: boolean;
}

/** Parse raw command args into items (newline-split, or comma-split if one line). */
function parseItems(raw: string): Item[] {
	const text = raw.trim();
	if (!text) return [];
	let parts = text.split(/\r?\n/).map((s) => s.trim()).filter(Boolean);
	if (parts.length <= 1) {
		parts = text.split(",").map((s) => s.trim()).filter(Boolean);
	}
	const seen = new Set<string>();
	const items: Item[] = [];
	for (const part of parts) {
		let label = part;
		let checked = false;
		const m = label.match(/^(\[x\]|\[ \]|\*|-\s*\[x\]|-\s*\[ \])\s+(.*)$/i);
		if (m) {
			checked = /x/i.test(m[1]);
			label = m[2].trim();
		}
		if (!label || seen.has(label)) continue;
		seen.add(label);
		items.push({ label, checked });
	}
	return items;
}

/**
 * Render the interactive checklist popup. Resolves to the checked labels, or
 * null if cancelled. Requires an interactive TUI.
 */
async function runChecklist(
	ctx: ExtensionContext,
	title: string,
	items: Item[],
): Promise<string[] | null> {
	if (ctx.mode !== "tui" || !ctx.hasUI) return null;
	if (items.length === 0) return null;

	return ctx.ui.custom<string[] | null>((tui, theme, keybindings, done) => {
		let filter = "";
		let cursor = 0; // index into the filtered view
		let top = 0; // scroll offset into the filtered view

		const filtered = (): Item[] => {
			if (!filter) return items;
			const f = filter.toLowerCase();
			return items.filter((it) => it.label.toLowerCase().includes(f));
		};

		const clampCursor = () => {
			const n = filtered().length;
			if (cursor >= n) cursor = Math.max(0, n - 1);
			if (cursor < top) top = cursor;
			if (cursor >= top + MAX_VISIBLE) top = cursor - MAX_VISIBLE + 1;
			if (top < 0) top = 0;
		};

		const refresh = () => {
			clampCursor();
			tui.requestRender();
		};

		function render(width: number): string[] {
			const safeWidth = Math.max(1, width);
			// Bound the visible window to the terminal height when known, leaving
			// room for header (3 lines) + footer (3 lines) of chrome.
			const termHeight = (tui as { height?: number }).height;
			const maxVisible =
				typeof termHeight === "number" && termHeight > 0
					? Math.max(1, Math.min(MAX_VISIBLE, termHeight - 6))
					: MAX_VISIBLE;
			if (cursor >= top + maxVisible) top = cursor - maxVisible + 1;
			if (top < 0) top = 0;

			const view = filtered();
			const checkedCount = items.filter((i) => i.checked).length;
			const lines: string[] = [];
			lines.push(
				theme.fg("accent", theme.bold(`✻ ${title} `)) +
					theme.fg("muted", `(${checkedCount}/${items.length} selected)`),
			);
			const filterLabel = filter
				? theme.fg("text", filter) + theme.fg("dim", ` — ${view.length} match`)
				: theme.fg("dim", "type to filter");
			lines.push(theme.fg("muted", "  filter: ") + filterLabel);
			lines.push("");

			if (view.length === 0) {
				lines.push(theme.fg("warning", "  no matches"));
			} else {
				const end = Math.min(top + maxVisible, view.length);
				for (let i = top; i < end; i++) {
					const it = view[i];
					const isCur = i === cursor;
					const pointer = isCur ? theme.fg("accent", "> ") : "  ";
					const box = it.checked ? theme.fg("success", "[x]") : theme.fg("dim", "[ ]");
					// Reserve columns for the pointer + box + separating space
					// ("> [x] " == 6 cols) and truncate only the label so the
					// checkbox is never cut off.
					const prefixWidth = 6;
					const labelWidth = Math.max(1, safeWidth - prefixWidth);
					const label = truncateToWidth(it.label, labelWidth);
					const nameText = isCur ? theme.bold(label) : label;
					const name = it.checked ? theme.fg("text", nameText) : theme.fg("dim", nameText);
					lines.push(`${pointer}${box} ${name}`);
				}
				if (top > 0 || end < view.length) {
					lines.push(theme.fg("dim", `  (${cursor + 1}/${view.length})`));
				}
			}

			lines.push("");
			lines.push(
				theme.fg("dim", "↑↓ move • space toggle • ^A all • ^D none • Enter confirm • Esc back"),
			);
			lines.push(theme.fg("accent", "─".repeat(Math.max(1, Math.min(safeWidth, 80)))));
			// Final safety net: clamp every line (header/footer/help included) so
			// nothing can ever exceed the terminal width and crash the renderer.
			return lines.map((line) => (visibleWidth(line) > safeWidth ? truncateToWidth(line, safeWidth) : line));
		}

		function handleInput(data: string): void {
			// Confirm / cancel
			if (keybindings.matches(data, "tui.select.confirm")) {
				return done(items.filter((i) => i.checked).map((i) => i.label));
			}
			if (keybindings.matches(data, "tui.select.cancel")) {
				if (filter) {
					filter = "";
					cursor = 0;
					top = 0;
					return refresh();
				}
				return done(null);
			}
			// Navigation
			if (keybindings.matches(data, "tui.select.up")) {
				cursor = Math.max(0, cursor - 1);
				return refresh();
			}
			if (keybindings.matches(data, "tui.select.down")) {
				cursor = Math.min(filtered().length - 1, cursor + 1);
				return refresh();
			}
			// Toggle current
			if (data === " ") {
				const view = filtered();
				if (view[cursor]) view[cursor].checked = !view[cursor].checked;
				return refresh();
			}
			// Bulk (affect filtered view)
			if (data === "\x01") {
				// Ctrl-A
				for (const it of filtered()) it.checked = true;
				return refresh();
			}
			if (data === "\x04") {
				// Ctrl-D
				for (const it of filtered()) it.checked = false;
				return refresh();
			}
			// Backspace edits filter
			if (data === "\x7f" || data === "\b") {
				filter = filter.slice(0, -1);
				cursor = 0;
				top = 0;
				return refresh();
			}
			// Printable char (excluding space, handled above) extends the filter
			if (data.length === 1 && data >= " " && data.charCodeAt(0) < 127) {
				filter += data;
				cursor = 0;
				top = 0;
				return refresh();
			}
		}

		return { render, invalidate: () => {}, handleInput };
	});
}

export default function (pi: ExtensionAPI) {
	// Command: user pastes a list, picks items, selection is fed back to the agent.
	pi.registerCommand("checklist", {
		description: "Pick from a pasted list (comma or newline separated); selection is sent back",
		handler: async (args, ctx) => {
			const items = parseItems(args ?? "");
			if (items.length === 0) {
				ctx.ui.notify(
					"Usage: /checklist a, b, c   (or a newline-separated list). Prefix an item with [x] to pre-check it.",
					"warning",
				);
				return;
			}
			const selected = await runChecklist(ctx, "Checklist", items);
			if (selected === null) {
				ctx.ui.notify("Checklist cancelled", "info");
				return;
			}
			if (selected.length === 0) {
				ctx.ui.notify("Nothing selected", "info");
				return;
			}
			const body = selected.map((s) => `- ${s}`).join("\n");
			pi.sendUserMessage(`I selected these ${selected.length} item(s) from the checklist:\n${body}`, {
				deliverAs: "followUp",
			});
		},
	});

	// Tool: the agent shows a list, the user checks items, selection returns to the LLM.
	const params = Type.Object({
		title: Type.Optional(Type.String({ description: "Popup heading, e.g. 'Pick MCP servers'" })),
		items: Type.Array(Type.String(), { description: "Items to present as checkboxes" }),
		preselected: Type.Optional(
			Type.Array(Type.String(), { description: "Items that should start checked" }),
		),
	});

	pi.registerTool({
		name: "checklist",
		label: "Checklist",
		description:
			"Show the user an interactive checkbox list and return the items they selected. Use when you have many candidates (skills, MCP servers, files, tasks) and need the user to choose which ones to act on.",
		promptSnippet: "Present a checkbox list to the user and get back their selected items",
		promptGuidelines: [
			"Use checklist when you want the user to pick a subset from many options before you proceed.",
		],
		parameters: params,
		async execute(_toolCallId, input, _signal, _onUpdate, ctx) {
			if (ctx.mode !== "tui" || !ctx.hasUI) {
				return {
					content: [{ type: "text", text: "Checklist unavailable: no interactive TUI." }],
					details: { cancelled: true, selected: [] },
				};
			}
			const pre = new Set(input.preselected ?? []);
			const seen = new Set<string>();
			const items: Item[] = [];
			for (const raw of input.items) {
				const label = String(raw).trim();
				if (!label || seen.has(label)) continue;
				seen.add(label);
				items.push({ label, checked: pre.has(label) });
			}
			if (items.length === 0) {
				return {
					content: [{ type: "text", text: "No items provided." }],
					details: { cancelled: true, selected: [] },
				};
			}
			const selected = await runChecklist(ctx, input.title ?? "Select items", items);
			if (selected === null) {
				return {
					content: [{ type: "text", text: "User cancelled the checklist." }],
					details: { cancelled: true, selected: [] },
				};
			}
			const summary = selected.length
				? `User selected ${selected.length} item(s):\n${selected.map((s) => `- ${s}`).join("\n")}`
				: "User selected nothing.";
			return {
				content: [{ type: "text", text: summary }],
				details: { cancelled: false, selected },
			};
		},
		renderResult(result, _options, theme, _context) {
			const details = result.details as { cancelled?: boolean; selected?: string[] } | undefined;
			if (!details || details.cancelled) return new Text(theme.fg("warning", "Checklist cancelled"), 0, 0);
			const sel = details.selected ?? [];
			if (sel.length === 0) return new Text(theme.fg("muted", "Nothing selected"), 0, 0);
			const lines = sel.map((s) => `${theme.fg("success", "✓ ")}${s}`);
			return new Text(lines.join("\n"), 0, 0);
		},
	});
}
