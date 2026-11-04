/**
 * Markdown pager for pi.
 *
 * Opens the latest user prompt and assistant reply in a scrollable overlay.
 * The pager can switch between rendered Markdown and exact raw response lines.
 *
 * Trigger: `/pager` command, or Ctrl+H.
 *
 * Controls:
 *   j / k or ↓ / ↑     source line down / up
 *   space / b          page down / up
 *   d / u              half page down / up
 *   g / G              top / bottom
 *   h / l              previous / next prompt-response pair
 *   m                  toggle rendered / raw Markdown
 *   p                  expand / collapse a long prompt
 *   w                  wrap / preserve structured raw lines
 *   v                  start visual source-line selection
 *   y                  copy the active-view line or selection
 *   /                  search the active view
 *   n / N              next / previous match
 *   q / Esc            close
 */

import {
	copyToClipboard,
	getMarkdownTheme,
	type ExtensionAPI,
	type ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import {
	Markdown,
	truncateToWidth,
	visibleWidth,
	wrapTextWithAnsi,
} from "@earendil-works/pi-tui";

const TERMINAL_SEQUENCE_RE = /(?:\x1b(?:\](?:[^\x07\x1b]|\x1b(?!\\))*(?:\x07|\x1b\\)|[PX^_](?:[^\x1b]|\x1b(?!\\))*(?:\x1b\\|$)|\[[0-?]*[ -/]*[@-~]|[()][0-2A-Z]|[0-9=><]|[ -/]*[@-~])|\x9b[0-?]*[ -/]*[@-~]|\x9d[^\x07\x9c]*(?:\x07|\x9c)|(?:\x90|\x98|\x9e|\x9f)[^\x9c]*(?:\x9c|$)|[\x80-\x9f])/g;
const TABLE_DELIMITER_RE = /^\s*\|?\s*:?-{3,}:?\s*(?:\|\s*:?-{3,}:?\s*)+\|?\s*$/;
const ASCII_DIAGRAM_RE = /[│├└┌┐┘┬┴┼─]|(?:^|\s)[├└]──|^\s*\+(?:[-=]+\+)+\s*$|^\s*\|.*\|\s*$|^\s*(?:\||\+|\\|`)-{2,}/;
const PROMPT_PREVIEW_WIDTH = 160;
const LONG_PROMPT_LINES = 2;

const stripAnsi = (text: string): string => text.replace(TERMINAL_SEQUENCE_RE, "");

type View = "rendered" | "raw";
type InputMode = "normal" | "search" | "visual";

interface Page {
	prompt: string;
	response: string;
}

interface ViewState {
	top: number;
	cursor: number;
	anchor: number;
	query: string;
	lastMatch: number;
}

interface PageState {
	rendered: ViewState;
	raw: ViewState;
	promptExpanded: boolean;
	wrapStructured: boolean;
}

interface DisplayRow {
	display: string;
	plain: string;
	logical?: number;
}

interface SearchEntry {
	text: string;
	logical: number;
	row: number;
}

interface Layout {
	rows: DisplayRow[];
	logicalCount: number;
	search: SearchEntry[];
	promptLong: boolean;
	rawLines?: RawSourceLine[];
}

interface MappingCache {
	sourceToRendered: Map<number, number>;
	renderedToSource: Map<number, number>;
	prefixRows: Map<number, number>;
}

export interface RawSourceLine {
	text: string;
	separator: string;
}

export interface RawDisplayRow {
	text: string;
	sourceLine: number;
	continuation: boolean;
	overflow: boolean;
}

function messageText(content: unknown): string {
	if (typeof content === "string") return content.trim();
	if (!Array.isArray(content)) return "";
	return content
		.map((block) => {
			const item = block as { type?: string; text?: string };
			if (item.type === "text") return item.text?.trim() ?? "";
			if (item.type === "image") return "[Image attached]";
			return "";
		})
		.filter(Boolean)
		.join("\n\n");
}

function rawAssistantText(content: unknown): string {
	if (typeof content === "string") return content;
	if (!Array.isArray(content)) return "";
	return content
		.map((block) => {
			const item = block as { type?: string; text?: string };
			return item.type === "text" ? (item.text ?? "") : "";
		})
		.join("");
}

/** Pair each assistant reply with the nearest prior user prompt. */
export function collectPages(branch: readonly unknown[]): Page[] {
	const pages: Page[] = [];
	let prompt = "";
	for (const raw of branch) {
		const entry = raw as { type?: string; message?: { role?: string; content?: unknown } };
		if (entry.type !== "message" || !entry.message) continue;
		if (entry.message.role === "user") {
			prompt = messageText(entry.message.content);
			continue;
		}
		if (entry.message.role !== "assistant") continue;
		const response = rawAssistantText(entry.message.content);
		if (response.trim()) pages.push({ prompt, response });
	}
	return pages;
}

export function promptMarkdown(page: Page): string {
	const prompt = page.prompt || "_Prompt unavailable_";
	return ["> [!PROMPT]", ...prompt.split("\n").map((line) => `> ${line}`)].join("\n");
}

export function collapsedPromptRows(prompt: string, displayLineCount: number, width: number): string[] {
	const summary = truncateToWidth(
		prompt.replace(/\s+/g, " ").trim(),
		Math.max(1, Math.min(PROMPT_PREVIEW_WIDTH, width)),
		"…",
	);
	return [
		summary,
		truncateToWidth(`p expand · ${displayLineCount} lines`, Math.max(1, width), "…"),
	];
}

/** Retained for callers that need one complete rendered Markdown document. */
export function pageMarkdown(page: Page): string {
	return `${promptMarkdown(page)}\n\n## Response\n\n${page.response}`;
}

function withoutBlockquotePrefix(line: string): string {
	let text = line;
	while (/^\s{0,3}>\s?/.test(text)) text = text.replace(/^\s{0,3}>\s?/, "");
	return text;
}

function fenceMarker(line: string): string | undefined {
	return /^\s{0,3}(`{3,}|~{3,})/.exec(withoutBlockquotePrefix(line))?.[1];
}

/** Mark fenced code, Markdown tables, and ASCII diagrams as structured lines. */
export function protectedRawLines(lines: readonly string[]): boolean[] {
	const protectedLines = lines.map(() => false);
	let fence: string | undefined;
	for (let index = 0; index < lines.length; index++) {
		const marker = fenceMarker(lines[index]);
		if (fence) {
			protectedLines[index] = true;
			if (
				marker &&
				marker[0] === fence[0] &&
				marker.length >= fence.length &&
				withoutBlockquotePrefix(lines[index]).trimStart().slice(marker.length).trim() === ""
			) {
				fence = undefined;
			}
			continue;
		}
		if (marker) {
			fence = marker;
			protectedLines[index] = true;
		}
	}

	for (let index = 0; index < lines.length - 1; index++) {
		if (protectedLines[index] || !lines[index].includes("|") || !TABLE_DELIMITER_RE.test(lines[index + 1])) continue;
		protectedLines[index] = true;
		protectedLines[index + 1] = true;
		let row = index + 2;
		while (row < lines.length && lines[row].trim() && lines[row].includes("|")) {
			protectedLines[row] = true;
			row++;
		}
		index = row - 1;
	}

	for (let index = 0; index < lines.length; index++) {
		if (ASCII_DIAGRAM_RE.test(lines[index])) protectedLines[index] = true;
	}
	return protectedLines;
}

function clippedRawLine(line: string, width: number): { text: string; overflow: boolean } {
	if (visibleWidth(line) <= width) return { text: line, overflow: false };
	if (width <= 2) return { text: truncateToWidth(line, width, ""), overflow: true };
	return { text: `${truncateToWidth(line, width - 2, "")} ›`, overflow: true };
}

export function splitRawLines(response: string): RawSourceLine[] {
	const lines: RawSourceLine[] = [];
	let start = 0;
	for (const match of response.matchAll(/\r\n|\n|\r/g)) {
		lines.push({ text: response.slice(start, match.index), separator: match[0] });
		start = (match.index ?? start) + match[0].length;
	}
	lines.push({ text: response.slice(start), separator: "" });
	return lines;
}

/** Build raw display rows while retaining an exact source-line index. */
export function buildRawRows(response: string, width: number, wrapStructured: boolean): {
	rows: RawDisplayRow[];
	sourceLines: RawSourceLine[];
} {
	const sourceLines = splitRawLines(response);
	const protectedLines = protectedRawLines(sourceLines.map((line) => stripAnsi(line.text)));
	const contentWidth = Math.max(1, width - 2);
	const rows: RawDisplayRow[] = [];

	for (let sourceLine = 0; sourceLine < sourceLines.length; sourceLine++) {
		const raw = stripAnsi(sourceLines[sourceLine].text).replace(/\t/g, "   ");
		if (protectedLines[sourceLine] && !wrapStructured) {
			const clipped = clippedRawLine(raw, contentWidth);
			rows.push({ text: `  ${clipped.text}`, sourceLine, continuation: false, overflow: clipped.overflow });
			continue;
		}
		const wrapped = wrapTextWithAnsi(raw, contentWidth);
		const parts = wrapped.length ? wrapped : [""];
		for (let part = 0; part < parts.length; part++) {
			rows.push({
				text: `${part === 0 ? "  " : "↳ "}${parts[part]}`,
				sourceLine,
				continuation: part > 0,
				overflow: false,
			});
		}
	}
	return { rows, sourceLines };
}

/** Copy complete original raw lines, including spaces and original separators. */
export function rawSelection(sourceLines: readonly RawSourceLine[], lo: number, hi: number): string {
	const first = Math.max(0, lo);
	const last = Math.min(sourceLines.length - 1, hi);
	return sourceLines
		.slice(first, last + 1)
		.map((line, index) => line.text + (index < last - first ? line.separator : ""))
		.join("");
}

export function normalizeAnchorText(text: string): string {
	const plain = stripAnsi(text).trim();
	if (TABLE_DELIMITER_RE.test(plain) || /^[├┼┤─\s]+$/.test(plain)) {
		return "__table_separator__";
	}
	return plain
		.replace(/^#{1,6}\s+/, "")
		.replace(/^>+\s*/, "")
		.replace(/^[-*+]\s+(?:\[[ xX✓○]\]\s+)?/, "")
		.replace(/^\d+[.)]\s+/, "")
		.replace(/[|│┌┐└┘├┤┬┴┼─═]+/g, " ")
		.replace(/[`*_~]/g, "")
		.replace(/\s+/g, " ")
		.trim()
		.toLowerCase();
}

export function visualFooter(selectionCount: number, view: View): string {
	return `-- VISUAL -- ${selectionCount} ${view === "raw" ? "source " : ""}line${selectionCount === 1 ? "" : "s"} · y yank · m ${view === "raw" ? "rendered" : "raw"} · j/k extend · Esc cancel`;
}

function newViewState(): ViewState {
	return { top: 0, cursor: 0, anchor: 0, query: "", lastMatch: -1 };
}

function newPageState(): PageState {
	return {
		rendered: newViewState(),
		raw: newViewState(),
		promptExpanded: false,
		wrapStructured: false,
	};
}

export async function openPager(
	ctx: ExtensionContext,
	copy: (text: string) => Promise<void> = copyToClipboard,
): Promise<void> {
	if (ctx.mode !== "tui" || !ctx.hasUI) {
		ctx.ui.notify("Pager needs the interactive TUI", "warning");
		return;
	}
	const pages = collectPages(ctx.sessionManager.getBranch());
	if (pages.length === 0) {
		ctx.ui.notify("No assistant reply to page yet", "info");
		return;
	}
	const pageStates = pages.map(newPageState);

	await ctx.ui.custom<boolean>(
		(tui, theme, keybindings, done) => {
			let current = pages.length - 1;
			let view: View = "rendered";
			let mode: InputMode = "normal";
			let copyNotice = "";
			let layout: Layout = { rows: [], logicalCount: 0, search: [], promptLong: false };
			let layoutKey = "";
			let lastInnerWidth = 80;
			const mappingCaches = new Map<string, MappingCache>();

			const pageState = () => pageStates[current];
			const viewState = () => pageState()[view];
			const invalidateLayout = () => {
				layoutKey = "";
			};

			const buildPromptRows = (innerWidth: number): { rows: DisplayRow[]; long: boolean } => {
				const prompt = pages[current].prompt || "Prompt unavailable";
				const bodyWidth = Math.max(1, innerWidth - 2);
				const fullRows = new Markdown(prompt, 0, 0, getMarkdownTheme()).render(bodyWidth);
				const long = fullRows.length > LONG_PROMPT_LINES;
				const body = long && !pageState().promptExpanded
					? collapsedPromptRows(prompt, fullRows.length, bodyWidth).map((line, index) =>
						index === 0 ? theme.fg("text", line) : theme.fg("dim", line),
					)
					: fullRows;
				const border = (text: string) => theme.fg("borderMuted", text);
				const label = "󰍡 Prompt";
				const topTail = ` ${"─".repeat(Math.max(0, innerWidth - visibleWidth(label) - 5))}╮`;
				const displays = [
					border("╭─ ") + theme.fg("accent", label) + border(topTail),
					...body.map((line) => border("│") + truncateToWidth(line, bodyWidth, "") + " ".repeat(Math.max(0, bodyWidth - visibleWidth(truncateToWidth(line, bodyWidth, "")))) + border("│")),
					border(`╰${"─".repeat(Math.max(0, innerWidth - 2))}╯`),
				];
				return {
					long,
					rows: displays.map((display) => ({ display, plain: stripAnsi(display) })),
				};
			};

			const buildLayout = (innerWidth: number, targetView: View = view): Layout => {
				const prompt = buildPromptRows(innerWidth);
				const heading = targetView === "raw" ? "Response · Raw Markdown" : "Response · Rendered";
				const rows: DisplayRow[] = [
					...prompt.rows,
					{ display: "", plain: "" },
					{ display: theme.fg("accent", theme.bold(heading)), plain: heading },
					{ display: "", plain: "" },
				];
				const search: SearchEntry[] = [];

				if (targetView === "rendered") {
					const responseRows = new Markdown(pages[current].response, 0, 0, getMarkdownTheme()).render(Math.max(1, innerWidth));
					for (let logical = 0; logical < responseRows.length; logical++) {
						const row = rows.length;
						const display = responseRows[logical];
						const plain = stripAnsi(display);
						rows.push({ display, plain, logical });
						search.push({ text: plain, logical, row });
					}
					return { rows, logicalCount: responseRows.length, search, promptLong: prompt.long };
				}

				const raw = buildRawRows(pages[current].response, innerWidth, pageState().wrapStructured);
				const firstRows = new Map<number, number>();
				for (const rawRow of raw.rows) {
					const row = rows.length;
					if (!firstRows.has(rawRow.sourceLine)) firstRows.set(rawRow.sourceLine, row);
					const markerWidth = rawRow.continuation ? 2 : 0;
					const display = rawRow.continuation
						? theme.fg("dim", "↳ ") + theme.fg("text", rawRow.text.slice(markerWidth))
						: theme.fg("text", rawRow.text);
					rows.push({ display, plain: rawRow.text, logical: rawRow.sourceLine });
				}
				for (let logical = 0; logical < raw.sourceLines.length; logical++) {
					search.push({ text: raw.sourceLines[logical].text, logical, row: firstRows.get(logical) ?? rows.length - 1 });
				}
				return { rows, logicalCount: raw.sourceLines.length, search, rawLines: raw.sourceLines, promptLong: prompt.long };
			};

			const ensureLayout = (innerWidth = lastInnerWidth): boolean => {
				const hadLayout = layoutKey !== "";
				const nextWidth = Math.max(1, innerWidth);
				const widthChanged = hadLayout && nextWidth !== lastInnerWidth;
				const sourceAnchor = widthChanged && view === "rendered"
					? renderedRowToSourceLine(viewState().cursor)
					: undefined;
				lastInnerWidth = nextWidth;
				const state = pageState();
				const key = [current, view, lastInnerWidth, state.promptExpanded, state.wrapStructured].join(":");
				const rebuilt = key !== layoutKey;
				if (rebuilt) {
					layout = buildLayout(lastInnerWidth);
					layoutKey = key;
				}
				const active = viewState();
				if (sourceAnchor !== undefined) active.cursor = sourceLineToRenderedRow(sourceAnchor);
				active.cursor = Math.max(0, Math.min(Math.max(0, layout.logicalCount - 1), active.cursor));
				active.anchor = Math.max(0, Math.min(Math.max(0, layout.logicalCount - 1), active.anchor));
				return rebuilt && hadLayout;
			};

			const mappingCache = (): MappingCache => {
				const key = `${current}:${lastInnerWidth}`;
				let cache = mappingCaches.get(key);
				if (!cache) {
					cache = {
						sourceToRendered: new Map(),
						renderedToSource: new Map(),
						prefixRows: new Map(),
					};
					mappingCaches.set(key, cache);
				}
				return cache;
			};

			const prefixRenderedRow = (sourceLine: number): number => {
				const cache = mappingCache();
				const cached = cache.prefixRows.get(sourceLine);
				if (cached !== undefined) return cached;
				const source = splitRawLines(pages[current].response);
				let prefix = "";
				for (let index = 0; index <= sourceLine && index < source.length; index++) {
					prefix += source[index].text;
					if (index < sourceLine) prefix += source[index].separator;
				}
				const row = Math.max(
					0,
					new Markdown(prefix, 0, 0, getMarkdownTheme()).render(lastInnerWidth).length - 1,
				);
				cache.prefixRows.set(sourceLine, row);
				return row;
			};

			const nearestMatch = (candidates: number[], expected: number): number | undefined =>
				candidates.sort((left, right) => Math.abs(left - expected) - Math.abs(right - expected))[0];

			const sourceLineToRenderedRow = (sourceLine: number): number => {
				const cache = mappingCache();
				const cached = cache.sourceToRendered.get(sourceLine);
				if (cached !== undefined) return cached;
				const source = splitRawLines(pages[current].response);
				const renderedLayout = buildLayout(lastInnerWidth, "rendered");
				const target = normalizeAnchorText(source[sourceLine]?.text ?? "");
				const expected = prefixRenderedRow(sourceLine);
				const exact: number[] = [];
				const partial: number[] = [];
				if (target) {
					for (const row of renderedLayout.rows) {
						if (row.logical === undefined) continue;
						const normalized = normalizeAnchorText(row.plain);
						if (normalized === target) exact.push(row.logical);
						else if (normalized.length > 2 && (normalized.includes(target) || target.includes(normalized))) partial.push(row.logical);
					}
				}
				const mapped = nearestMatch(exact, expected) ?? nearestMatch(partial, expected) ?? prefixRenderedRow(sourceLine);
				const result = Math.max(0, Math.min(Math.max(0, renderedLayout.logicalCount - 1), mapped));
				cache.sourceToRendered.set(sourceLine, result);
				cache.renderedToSource.set(result, sourceLine);
				return result;
			};

			const renderedRowToSourceLine = (renderedRow: number): number => {
				const cache = mappingCache();
				const cached = cache.renderedToSource.get(renderedRow);
				if (cached !== undefined) return cached;
				const source = splitRawLines(pages[current].response);
				const renderedLayout = view === "rendered" ? layout : buildLayout(lastInnerWidth, "rendered");
				const row = renderedLayout.rows.find((item) => item.logical === renderedRow);
				const target = normalizeAnchorText(row?.plain ?? "");
				const expected = renderedRow;
				const exact: number[] = [];
				const partial: number[] = [];
				if (target) {
					for (let index = 0; index < source.length; index++) {
						const normalized = normalizeAnchorText(source[index].text);
						if (normalized === target) exact.push(index);
						else if (normalized.length > 2 && (normalized.includes(target) || target.includes(normalized))) partial.push(index);
					}
				}
				const nearestSource = (candidates: number[]): number | undefined =>
					candidates.sort(
						(left, right) =>
							Math.abs(prefixRenderedRow(left) - expected) -
							Math.abs(prefixRenderedRow(right) - expected),
					)[0];
				let mapped = nearestSource(exact) ?? nearestSource(partial);
				if (mapped === undefined) {
					let low = 0;
					let high = Math.max(0, source.length - 1);
					mapped = 0;
					while (low <= high) {
						const middle = Math.floor((low + high) / 2);
						if (prefixRenderedRow(middle) <= renderedRow) {
							mapped = middle;
							low = middle + 1;
						} else {
							high = middle - 1;
						}
					}
				}
				const result = Math.max(0, Math.min(Math.max(0, source.length - 1), mapped));
				cache.renderedToSource.set(renderedRow, result);
				cache.sourceToRendered.set(result, renderedRow);
				return result;
			};

			const selectionRange = (): [number, number] => {
				const state = viewState();
				return mode === "visual"
					? [Math.min(state.anchor, state.cursor), Math.max(state.anchor, state.cursor)]
					: [state.cursor, state.cursor];
			};

			const clampTop = () => {
				const state = viewState();
				const maxTop = Math.max(0, layout.rows.length - viewportRows());
				state.top = Math.max(0, Math.min(maxTop, state.top));
			};

			const rowsForLogical = (logical: number): [number, number] | undefined => {
				let first = -1;
				let last = -1;
				for (let row = 0; row < layout.rows.length; row++) {
					if (layout.rows[row].logical !== logical) continue;
					if (first < 0) first = row;
					last = row;
				}
				return first < 0 ? undefined : [first, last];
			};

			const followCursor = () => {
				ensureLayout();
				const state = viewState();
				const range = rowsForLogical(state.cursor);
				if (!range) return;
				const [first, last] = range;
				const height = viewportRows();
				if (last - first + 1 >= height) state.top = first;
				else if (first < state.top) state.top = first;
				else if (last >= state.top + height) state.top = last - height + 1;
				clampTop();
			};

			const scrollRows = (delta: number) => {
				ensureLayout();
				const state = viewState();
				state.top += delta;
				clampTop();
				const row = layout.rows.slice(state.top).find((entry) => entry.logical !== undefined);
				if (row?.logical !== undefined) state.cursor = row.logical;
			};

			const yank = async () => {
				ensureLayout();
				const [lo, hi] = selectionRange();
				let text: string;
				if (view === "raw") {
					text = rawSelection(layout.rawLines ?? [], lo, hi);
				} else {
					text = layout.rows
						.filter((row) => row.logical !== undefined && row.logical >= lo && row.logical <= hi)
						.map((row) => row.plain.replace(/\s+$/, ""))
						.join("\n");
				}
				try {
					await copy(text);
					const count = hi - lo + 1;
					copyNotice = `yanked ${count} ${view === "raw" ? "source " : ""}line${count === 1 ? "" : "s"}`;
				} catch {
					copyNotice = "copy failed";
				}
				mode = "normal";
				tui.requestRender();
			};

			const jumpToMatch = (direction: 1 | -1) => {
				ensureLayout();
				const state = viewState();
				if (!state.query || layout.search.length === 0) return;
				const query = state.query.toLowerCase();
				for (let step = 1; step <= layout.search.length; step++) {
					const index = ((state.lastMatch + direction * step) % layout.search.length + layout.search.length) % layout.search.length;
					const entry = layout.search[index];
					if (!entry.text.toLowerCase().includes(query)) continue;
					state.lastMatch = index;
					state.cursor = entry.logical;
					const matchingRow = view === "raw"
						? layout.rows.findIndex(
							(row) => row.logical === entry.logical && row.plain.toLowerCase().includes(query),
						)
						: -1;
					state.top = matchingRow >= 0 ? matchingRow : entry.row;
					clampTop();
					return;
				}
			};

			const loadReply = (index: number) => {
				const next = Math.max(0, Math.min(pages.length - 1, index));
				if (next === current) return;
				current = next;
				mode = "normal";
				copyNotice = "";
				invalidateLayout();
			};

			const CHROME_ROWS = 6;
			const boxRows = () => Math.max(CHROME_ROWS + 1, Math.floor((process.stdout.rows ?? 40) * 0.9));
			const viewportRows = () => Math.max(1, boxRows() - CHROME_ROWS);

			function render(width: number): string[] {
				if (width < 6) return [truncateToWidth("Pager", Math.max(1, width), "")];
				const boxW = width;
				const innerW = boxW - 4;
				const rebuilt = ensureLayout(innerW);
				if (rebuilt) followCursor();
				else clampTop();
				const state = viewState();
				const height = viewportRows();
				const end = Math.min(state.top + height, layout.rows.length);
				const border = (text: string) => theme.fg("muted", text);
				const boxRow = (content: string): string => {
					const fitted = truncateToWidth(content, innerW, "");
					return border("│ ") + fitted + " ".repeat(Math.max(0, innerW - visibleWidth(fitted))) + border(" │");
				};
				const position = layout.rows.length === 0 ? "empty" : `${state.top + 1}–${end}/${layout.rows.length}`;
				const viewLabel = view === "raw" ? "raw Markdown" : "rendered";
				const output: string[] = [
					border(`╭${"─".repeat(boxW - 2)}╮`),
					boxRow(
						theme.fg("accent", theme.bold("✻ Pager ")) +
							theme.fg("muted", `· ${viewLabel} · reply ${current + 1}/${pages.length} · lines ${position}`),
					),
					border(`├${"─".repeat(boxW - 2)}┤`),
				];

				const [lo, hi] = selectionRange();
				for (let row = state.top; row < end; row++) {
					const item = layout.rows[row];
					const selected = item.logical !== undefined && item.logical >= lo && item.logical <= hi;
					const onCursor = item.logical !== undefined && item.logical === state.cursor;
					output.push(
						selected || onCursor
							? boxRow(theme.bg("selectedBg", theme.fg("text", item.plain)))
							: boxRow(item.display),
					);
				}
				for (let row = end - state.top; row < height; row++) output.push(boxRow(""));

				output.push(border(`├${"─".repeat(boxW - 2)}┤`));
				if (mode === "search") {
					output.push(boxRow(theme.fg("accent", `/${view} `) + theme.fg("text", state.query) + theme.fg("dim", "▏")));
				} else if (mode === "visual") {
					output.push(boxRow(theme.fg("accent", visualFooter(hi - lo + 1, view))));
				} else {
					const promptHelp = layout.promptLong ? " · p prompt" : "";
					const wrapHelp = view === "raw"
						? ` · w ${pageState().wrapStructured ? "preserve structures" : "wrap structures"}`
						: "";
					const help = `m ${view === "raw" ? "rendered" : "raw"}${promptHelp}${wrapHelp} · v visual · y yank · / search · q close`;
					output.push(boxRow(theme.fg("dim", copyNotice ? `${help}   (${copyNotice})` : help)));
				}
				output.push(border(`╰${"─".repeat(boxW - 2)}╯`));
				return output;
			}

			function handleInput(data: string): void {
				ensureLayout();
				const state = viewState();
				if (mode === "search") {
					if (keybindings.matches(data, "tui.select.confirm")) {
						mode = "normal";
						jumpToMatch(1);
						tui.requestRender();
						return;
					}
					if (keybindings.matches(data, "tui.select.cancel")) {
						mode = "normal";
						state.query = "";
						tui.requestRender();
						return;
					}
					if (data === "\x7f" || data === "\b") {
						state.query = state.query.slice(0, -1);
						state.lastMatch = -1;
						tui.requestRender();
						return;
					}
					if (data.length === 1 && data.charCodeAt(0) >= 32) {
						state.query += data;
						state.lastMatch = -1;
						tui.requestRender();
					}
					return;
				}

				if (keybindings.matches(data, "tui.select.cancel")) {
					if (mode === "visual") {
						mode = "normal";
						tui.requestRender();
						return;
					}
					done(true);
					return;
				}
				if (data === "q") {
					done(true);
					return;
				}
				if (data === "m") {
					const sourceAnchor = view === "raw"
						? state.cursor
						: renderedRowToSourceLine(state.cursor);
					view = view === "raw" ? "rendered" : "raw";
					mode = "normal";
					copyNotice = "";
					invalidateLayout();
					ensureLayout();
					const target = viewState();
					target.cursor = view === "raw"
						? sourceAnchor
						: sourceLineToRenderedRow(sourceAnchor);
					target.anchor = target.cursor;
					followCursor();
					tui.requestRender();
					return;
				}
				if (data === "p" && layout.promptLong) {
					pageState().promptExpanded = !pageState().promptExpanded;
					mode = "normal";
					invalidateLayout();
					followCursor();
					tui.requestRender();
					return;
				}
				if (data === "w" && view === "raw") {
					pageState().wrapStructured = !pageState().wrapStructured;
					mode = "normal";
					invalidateLayout();
					followCursor();
					tui.requestRender();
					return;
				}
				if (data === "v") {
					if (mode === "visual") mode = "normal";
					else {
						mode = "visual";
						state.anchor = state.cursor;
					}
					tui.requestRender();
					return;
				}
				if (data === "y") {
					void yank();
					return;
				}

				const maxLogical = Math.max(0, layout.logicalCount - 1);
				if (data === "j" || keybindings.matches(data, "tui.select.down")) state.cursor++;
				else if (data === "k" || keybindings.matches(data, "tui.select.up")) state.cursor--;
				else if (data === " " || data === "f") scrollRows(viewportRows());
				else if (data === "b") scrollRows(-viewportRows());
				else if (data === "d") scrollRows(Math.floor(viewportRows() / 2));
				else if (data === "u") scrollRows(-Math.floor(viewportRows() / 2));
				else if (data === "g") {
					state.cursor = 0;
					state.top = 0;
				} else if (data === "G") {
					state.cursor = maxLogical;
					const range = rowsForLogical(maxLogical);
					state.top = range?.[1] ?? layout.rows.length - 1;
					clampTop();
				} else if (data === "h") loadReply(current - 1);
				else if (data === "l") loadReply(current + 1);
				else if (data === "/") mode = "search";
				else if (data === "n") jumpToMatch(1);
				else if (data === "N") jumpToMatch(-1);
				else return;

				state.cursor = Math.max(0, Math.min(maxLogical, state.cursor));
				if (["j", "k"].includes(data) || keybindings.matches(data, "tui.select.down") || keybindings.matches(data, "tui.select.up")) {
					followCursor();
				}
				tui.requestRender();
			}

			return {
				render,
				invalidate: invalidateLayout,
				handleInput,
			};
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
		description: "Page through the latest prompt and assistant response",
		handler: async (_args, ctx) => {
			await openPager(ctx);
		},
	});

	pi.registerShortcut("ctrl+h", {
		description: "Open the prompt and response pager",
		handler: async (ctx) => {
			await openPager(ctx);
		},
	});
}

if (import.meta.main) {
	const { deepStrictEqual: equal, strictEqual } = await import("node:assert");
	const { initTheme } = await import("@earendil-works/pi-coding-agent");
	initTheme("dark", false);
	const pages = collectPages([
		{ type: "message", message: { role: "user", content: "First prompt" } },
		{ type: "message", message: { role: "assistant", content: [{ type: "text", text: "First reply" }] } },
		{ type: "message", message: { role: "toolResult", content: "ignored" } },
		{ type: "message", message: { role: "user", content: [{ type: "image" }, { type: "text", text: "Second prompt" }] } },
		{ type: "message", message: { role: "assistant", content: [{ type: "text", text: "Second reply" }] } },
	]);
	equal(pages, [
		{ prompt: "First prompt", response: "First reply" },
		{ prompt: "[Image attached]\n\nSecond prompt", response: "Second reply" },
	]);
	equal(
		collectPages([
			{ type: "message", message: { role: "user", content: "Prompt" } },
			{ type: "message", message: { role: "assistant", content: [{ type: "text", text: "  raw\n" }, { type: "text", text: "tail  " }] } },
		])[0].response,
		"  raw\ntail  ",
	);
	strictEqual(promptMarkdown({ prompt: "line 1\nline 2\nline 3", response: "" }).includes("line 3"), true);
	const collapsed = collapsedPromptRows("one two three four five six", 8, 16);
	strictEqual(collapsed.length, 2);
	strictEqual(collapsed.every((line) => visibleWidth(line) <= 16), true);

	const raw = [
		"This prose line is long enough to wrap across display rows.",
		"```text",
		"a very long code line that must stay on one source row",
		"```",
		"| A | B |",
		"|---|---|",
		"| 1 | 2 |",
		"└── a very long tree line that must stay on one source row",
	].join("\n");
	const protectedLines = protectedRawLines(raw.split("\n"));
	equal(protectedLines, [false, true, true, true, true, true, true, true]);
	const preserved = buildRawRows(raw, 24, false);
	strictEqual(preserved.rows.filter((row) => row.sourceLine === 0).length > 1, true);
	strictEqual(preserved.rows.filter((row) => row.sourceLine === 2).length, 1);
	strictEqual(preserved.rows.find((row) => row.sourceLine === 2)?.overflow, true);
	const wrapped = buildRawRows(raw, 24, true);
	strictEqual(wrapped.rows.filter((row) => row.sourceLine === 2).length > 1, true);
	strictEqual(
		rawSelection(splitRawLines("  first  \r\n\tsecond  \n"), 0, 2),
		"  first  \r\n\tsecond  \n",
	);
	const ansiSource = "\x1b[31mred\x1b[0m";
	strictEqual(buildRawRows(ansiSource, 40, false).rows[0].text.includes("\x1b[31m"), false);
	strictEqual(rawSelection(splitRawLines(ansiSource), 0, 0), ansiSource);
	equal(stripAnsi("a\x1b]8;;url\x1b\\b"), "ab");
	equal(stripAnsi("a\x1b_hidden\x1b\\b"), "ab");
	equal(stripAnsi("a\x1bPdata\x1b\\b"), "ab");
	equal(stripAnsi("a\x1b(0b"), "ab");
	equal(stripAnsi("a\x1b7b"), "ab");
	equal(stripAnsi("a\x9b31mb"), "ab");
	equal(stripAnsi("a\x9fdata\x9cb"), "ab");
	const fences = protectedRawLines([
		"~~~~text",
		"inside",
		"``` mismatch",
		"~~~~",
		"> ````js",
		"> quoted code",
		"> ````",
		"+---+---+",
		"| A | B |",
		"+---+---+",
		"ordinary | prose",
	]);
	equal(fences, [true, true, true, true, true, true, true, true, true, true, false]);
	strictEqual(visibleWidth(buildRawRows("1234\t1234567", 20, false).rows[0].text) <= 20, true);
	strictEqual(normalizeAnchorText("| alpha | beta |"), normalizeAnchorText("│ alpha │ beta │"));
	strictEqual(normalizeAnchorText("|---|---|"), normalizeAnchorText("├─────┼──────┤"));
	strictEqual(visualFooter(2, "raw").includes("Y raw"), false);
	strictEqual(visualFooter(2, "raw").includes("m rendered"), true);

	let copied = "";
	const longResponse = "# Heading\r\n\r\nTarget **bold** text\n" + Array.from(
		{ length: 57 },
		(_value, index) => `└── line ${index + 4} with structured content that can wrap`,
	).join("\n");
	const branch = [
		{ type: "message", message: { role: "user", content: "prompt one\nprompt two\nprompt three\nprompt four" } },
		{ type: "message", message: { role: "assistant", content: longResponse } },
	];
	const fakeTheme = {
		fg: (_color: string, text: string) => text,
		bg: (_color: string, text: string) => text,
		bold: (text: string) => text,
	};
	await openPager(
		{
			mode: "tui",
			hasUI: true,
			sessionManager: { getBranch: () => branch },
			ui: {
				notify() {},
				async custom(factory: (tui: unknown, theme: unknown, keybindings: unknown, done: (value: boolean) => void) => {
					render(width: number): string[];
					handleInput?(data: string): void;
				}) {
					const component = factory(
						{ requestRender() {} },
						fakeTheme,
						{
							matches(data: string, action: string) {
								return (action === "tui.select.cancel" && data === "escape") ||
									(action === "tui.select.confirm" && data === "enter") ||
									(action === "tui.select.up" && data === "up") ||
									(action === "tui.select.down" && data === "down");
							},
						},
						() => {},
					);
					let output = component.render(80).join("\n");
					strictEqual(output.includes("rendered"), true);
					strictEqual(output.includes("p expand"), true);
					component.handleInput?.("p");
					output = component.render(80).join("\n");
					strictEqual(output.includes("prompt four"), true);
					component.handleInput?.("j");
					component.handleInput?.("j");
					component.handleInput?.("m");
					output = component.render(80).join("\n");
					strictEqual(output.includes("raw Markdown"), true);
					component.handleInput?.("y");
					await new Promise<void>((resolve) => queueMicrotask(resolve));
					strictEqual(copied, "Target **bold** text");
					component.handleInput?.("m");
					component.handleInput?.("m");
					component.handleInput?.("y");
					await new Promise<void>((resolve) => queueMicrotask(resolve));
					strictEqual(copied, "Target **bold** text");
					output = component.render(80).join("\n");
					strictEqual(output.includes("-- VISUAL --"), false);
					component.handleInput?.("G");
					component.handleInput?.("w");
					output = component.render(80).join("\n");
					strictEqual(output.includes("preserve structures"), true);
					component.handleInput?.("y");
					await new Promise<void>((resolve) => queueMicrotask(resolve));
					strictEqual(copied, "└── line 60 with structured content that can wrap");
					return true;
				},
			},
		} as unknown as ExtensionContext,
		async (text) => { copied = text; },
	);

	let mappedCopy = "";
	const wrappedLine = Array.from({ length: 32 }, (_value, index) => `word${index}`).join(" ");
	const mappingResponse = [
		wrappedLine,
		"",
		"duplicate",
		"after first",
		"",
		"| alpha | beta |",
		"|---|---|",
		"| one | two |",
		"",
		"duplicate",
		"after second",
		"",
		"widthtarget",
	].join("\n");
	const mappingBranch = [
		{ type: "message", message: { role: "user", content: "mapping prompt" } },
		{ type: "message", message: { role: "assistant", content: mappingResponse } },
	];
	await openPager(
		{
			mode: "tui",
			hasUI: true,
			sessionManager: { getBranch: () => mappingBranch },
			ui: {
				notify() {},
				async custom(factory: (tui: unknown, theme: unknown, keybindings: unknown, done: (value: boolean) => void) => {
					render(width: number): string[];
					handleInput?(data: string): void;
				}) {
					const component = factory(
						{ requestRender() {} },
						fakeTheme,
						{
							matches(data: string, action: string) {
								return (action === "tui.select.cancel" && data === "escape") ||
									(action === "tui.select.confirm" && data === "enter") ||
									(action === "tui.select.up" && data === "up") ||
									(action === "tui.select.down" && data === "down");
							},
						},
						() => {},
					);
					component.render(40);
					component.handleInput?.("j");
					component.handleInput?.("j");
					component.handleInput?.("y");
					await new Promise<void>((resolve) => queueMicrotask(resolve));
					const wrappedSegment = mappedCopy;
					component.handleInput?.("m");
					component.handleInput?.("m");
					component.handleInput?.("y");
					await new Promise<void>((resolve) => queueMicrotask(resolve));
					strictEqual(mappedCopy, wrappedSegment);

					component.handleInput?.("/");
					for (const char of "duplicate") component.handleInput?.(char);
					component.handleInput?.("enter");
					component.handleInput?.("n");
					component.handleInput?.("m");
					component.handleInput?.("j");
					component.handleInput?.("y");
					await new Promise<void>((resolve) => queueMicrotask(resolve));
					strictEqual(mappedCopy, "after second");

					component.handleInput?.("m");
					component.handleInput?.("/");
					component.handleInput?.("escape");
					component.handleInput?.("/");
					for (const char of "alpha") component.handleInput?.(char);
					component.handleInput?.("enter");
					component.handleInput?.("m");
					component.handleInput?.("y");
					await new Promise<void>((resolve) => queueMicrotask(resolve));
					strictEqual(mappedCopy, "| alpha | beta |");

					component.handleInput?.("m");
					component.handleInput?.("/");
					component.handleInput?.("escape");
					component.handleInput?.("/");
					for (const char of "widthtarget") component.handleInput?.(char);
					component.handleInput?.("enter");
					component.render(100);
					const narrowOutput = component.render(24).join("\n");
					strictEqual(narrowOutput.includes("widthtarget"), true);
					return true;
				},
			},
		} as unknown as ExtensionContext,
		async (text) => { mappedCopy = text; },
	);
	console.log("pager.ts self-check: ok");
}
