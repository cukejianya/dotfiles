/**
 * Markdown pager for pi.
 *
 * Opens the latest assistant reply in a scrollable, full-screen overlay so you
 * can page through long markdown answers without scrolling the whole terminal.
 * Only assistant *markdown* is paged — tool calls, diffs, and thinking are left
 * alone.
 *
 * Trigger: `/pager` command, or Ctrl+H.
 *
 * Controls (NORMAL):
 *   j / k or ↓ / ↑     line down / up
 *   space / b          page down / up
 *   d / u              half page down / up
 *   g / G              top / bottom
 *   h / l              previous / next assistant reply in the session
 *   v                  start visual line selection (j/k extend it)
 *   y                  yank: in visual mode copy the selection, else the current line
 *   /                  search (INSERT); Enter jumps to match
 *   n / N              next / previous match
 *   q / Esc            close
 *
 * Placement: ~/.config/pi/agent/extensions/pager.ts (auto-discovered).
 */

import {
	copyToClipboard,
	getMarkdownTheme,
	type ExtensionAPI,
	type ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { Markdown, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const stripAnsi = (s: string): string => s.replace(/\x1b\[[0-9;]*m/g, "");

/** Collect every assistant message's markdown text from the branch, in order. */
function assistantMarkdowns(ctx: ExtensionContext): string[] {
	const branch = ctx.sessionManager.getBranch();
	const out: string[] = [];
	for (const raw of branch) {
		const entry = raw as { type?: string; message?: { role?: string; content?: unknown[] } };
		if (entry.type !== "message" || entry.message?.role !== "assistant") continue;
		const parts: string[] = [];
		for (const block of entry.message.content ?? []) {
			const b = block as { type?: string; text?: string };
			if (b.type === "text" && b.text?.trim()) parts.push(b.text.trim());
		}
		if (parts.length > 0) out.push(parts.join("\n\n"));
	}
	return out;
}

async function openPager(ctx: ExtensionContext): Promise<void> {
	if (ctx.mode !== "tui" || !ctx.hasUI) {
		ctx.ui.notify("Pager needs the interactive TUI", "warning");
		return;
	}
	const texts = assistantMarkdowns(ctx);
	if (texts.length === 0) {
		ctx.ui.notify("No assistant reply to page yet", "info");
		return;
	}

	await ctx.ui.custom<boolean>(
		(tui, theme, keybindings, done) => {
			let current = texts.length - 1; // start on the latest reply
			let md = new Markdown(texts[current], 0, 0, getMarkdownTheme());

			let top = 0;
			let mode: "normal" | "search" | "visual" = "normal";
			let query = "";
			let lastMatch = -1;
			// Cursor line (absolute index into `lines`) and the visual anchor.
			let cursor = 0;
			let anchor = 0;
			let copyNotice = "";

			// Rendered-line cache, rebuilt when width changes.
			let cachedWidth = -1;
			let lines: string[] = [];
			let plain: string[] = [];

			// Overlay box is ~90% of the terminal height. The box has 6 chrome rows:
			// top border, header, header divider, footer divider, footer, bottom border.
			const CHROME_ROWS = 6;
			const boxRows = () => Math.max(CHROME_ROWS + 1, Math.floor((process.stdout.rows ?? 40) * 0.9));
			const viewportRows = () => Math.max(1, boxRows() - CHROME_ROWS);

			const ensureLines = (contentWidth: number) => {
				if (contentWidth === cachedWidth && lines.length) return;
				cachedWidth = contentWidth;
				lines = md.render(Math.max(1, contentWidth));
				plain = lines.map(stripAnsi);
			};

			// Switch to another reply, resetting scroll/search state.
			const loadReply = (idx: number) => {
				const next = Math.max(0, Math.min(texts.length - 1, idx));
				if (next === current) return;
				current = next;
				md = new Markdown(texts[current], 0, 0, getMarkdownTheme());
				cachedWidth = -1;
				lines = [];
				plain = [];
				top = 0;
				cursor = 0;
				anchor = 0;
				mode = "normal";
				lastMatch = -1;
			};

			// Selected line range [lo, hi] in visual mode (else just the cursor).
			const selRange = (): [number, number] =>
				mode === "visual" ? [Math.min(anchor, cursor), Math.max(anchor, cursor)] : [cursor, cursor];

			// Keep the cursor within the viewport by nudging `top`.
			const followCursor = () => {
				const vh = viewportRows();
				if (cursor < top) top = cursor;
				else if (cursor >= top + vh) top = cursor - vh + 1;
			};

			const yank = async () => {
				const [lo, hi] = selRange();
				const text = plain
					.slice(lo, hi + 1)
					.map((line) => line.replace(/\s+$/, ""))
					.join("\n");
				const n = hi - lo + 1;
				try {
					await copyToClipboard(text);
					copyNotice = `yanked ${n} line${n === 1 ? "" : "s"}`;
				} catch {
					copyNotice = "copy failed";
				}
				mode = "normal";
				tui.requestRender();
			};

			const clampTop = () => {
				const maxTop = Math.max(0, lines.length - viewportRows());
				if (top > maxTop) top = maxTop;
				if (top < 0) top = 0;
			};

			const jumpToMatch = (from: number, dir: 1 | -1) => {
				if (!query) return;
				const q = query.toLowerCase();
				const n = plain.length;
				for (let step = 1; step <= n; step++) {
					const idx = ((from + dir * step) % n + n) % n;
					if (plain[idx].toLowerCase().includes(q)) {
						lastMatch = idx;
						cursor = idx;
						top = idx; // put the match at the top of the viewport
						clampTop();
						return;
					}
				}
			};

			function render(width: number): string[] {
				const boxW = Math.max(10, width);
				const innerW = boxW - 4; // borders + 1 space padding each side
				ensureLines(innerW);
				clampTop();
				const vh = viewportRows();
				const border = (s: string) => theme.fg("muted", s);

				// A single bordered row: "│ <content padded to innerW> │"
				const boxRow = (content: string): string => {
					const fitted = truncateToWidth(content, innerW, "");
					const pad = Math.max(0, innerW - visibleWidth(fitted));
					return border("│ ") + fitted + " ".repeat(pad) + border(" │");
				};

				const total = lines.length;
				const end = Math.min(top + vh, total);
				const pos = total === 0 ? "empty" : `${top + 1}–${end}/${total}`;

				const out: string[] = [];
				out.push(border("╭" + "─".repeat(boxW - 2) + "╮"));
				out.push(
					boxRow(
						theme.fg("accent", theme.bold("✻ Pager ")) +
							theme.fg("muted", `— reply ${current + 1}/${texts.length} · lines ${pos}`),
					),
				);
				out.push(border("├" + "─".repeat(boxW - 2) + "┤"));

				// Body window (highlight selection / cursor in visual mode)
				const [lo, hi] = selRange();
				for (let i = top; i < end; i++) {
					const inSel = mode === "visual" && i >= lo && i <= hi;
					const onCursor = i === cursor;
					if (inSel || onCursor) {
						const plainLine = plain[i] ?? "";
						out.push(boxRow(theme.bg("selectedBg", theme.fg("text", plainLine))));
					} else {
						out.push(boxRow(lines[i]));
					}
				}
				for (let i = end - top; i < vh; i++) out.push(boxRow(""));

				out.push(border("├" + "─".repeat(boxW - 2) + "┤"));
				if (mode === "search") {
					out.push(boxRow(theme.fg("accent", "/") + theme.fg("text", query) + theme.fg("dim", "▏")));
				} else if (mode === "visual") {
					const n = hi - lo + 1;
					out.push(
						boxRow(
							theme.fg("accent", `-- VISUAL -- ${n} line${n === 1 ? "" : "s"}`) +
								theme.fg("dim", "  ·  j/k extend · y yank · Esc cancel"),
						),
					);
				} else {
					const help =
						"j/k · space/b · g/G · h/l reply · v visual · y yank line · / search · q close";
					out.push(boxRow(theme.fg("dim", copyNotice ? `${help}   (${copyNotice})` : help)));
				}
				out.push(border("╰" + "─".repeat(boxW - 2) + "╯"));
				return out;
			}

			function handleInput(data: string): void {
				const vh = viewportRows();

				if (mode === "search") {
					if (keybindings.matches(data, "tui.select.confirm")) {
						mode = "normal";
						jumpToMatch(top - 1, 1);
						tui.requestRender();
						return;
					}
					if (keybindings.matches(data, "tui.select.cancel")) {
						mode = "normal";
						query = "";
						tui.requestRender();
						return;
					}
					if (data === "\x7f" || data === "\b") {
						query = query.slice(0, -1);
						tui.requestRender();
						return;
					}
					if (data.length === 1 && data.charCodeAt(0) >= 32) {
						query += data;
						tui.requestRender();
						return;
					}
					return;
				}

				// NORMAL / VISUAL mode
				if (keybindings.matches(data, "tui.select.cancel")) {
					if (mode === "visual") { mode = "normal"; tui.requestRender(); return; }
					done(true);
					return;
				}
				if (data === "q") { done(true); return; }

				if (data === "v") {
					if (mode === "visual") mode = "normal";
					else { mode = "visual"; anchor = cursor; }
					tui.requestRender();
					return;
				}
				if (data === "y") { void yank(); return; }

				const maxLine = Math.max(0, lines.length - 1);
				if (data === "j" || keybindings.matches(data, "tui.select.down")) { cursor += 1; }
				else if (data === "k" || keybindings.matches(data, "tui.select.up")) { cursor -= 1; }
				else if (data === " " || data === "f") { cursor += vh; }
				else if (data === "b") { cursor -= vh; }
				else if (data === "d") { cursor += Math.floor(vh / 2); }
				else if (data === "u") { cursor -= Math.floor(vh / 2); }
				else if (data === "g") { cursor = 0; }
				else if (data === "G") { cursor = maxLine; }
				else if (data === "h") { loadReply(current - 1); }
				else if (data === "l") { loadReply(current + 1); }
				else if (data === "/") { mode = "search"; query = ""; }
				else if (data === "n") { jumpToMatch(lastMatch, 1); }
				else if (data === "N") { jumpToMatch(lastMatch, -1); }
				else { return; }

				cursor = Math.max(0, Math.min(Math.max(0, lines.length - 1), cursor));
				followCursor();
				clampTop();
				tui.requestRender();
			}

			return { render, invalidate: () => { cachedWidth = -1; }, handleInput };
		},
		{
			overlay: true,
			overlayOptions: {
				width: "90%",
				height: "90%",
				maxHeight: "90%",
				anchor: "center",
			},
		},
	);
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand("pager", {
		description: "Page through the latest assistant markdown reply in a scrollable overlay",
		handler: async (_args, ctx) => {
			await openPager(ctx);
		},
	});

	pi.registerShortcut("ctrl+h", {
		description: "Open the markdown pager for the latest assistant reply",
		handler: async (ctx) => {
			await openPager(ctx);
		},
	});
}
