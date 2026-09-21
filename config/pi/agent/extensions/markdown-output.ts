/**
 * Editorial Markdown output for pi.
 *
 * Pi has no public renderer hook for standard assistant messages. This
 * extension wraps the Markdown component and restores it at session shutdown.
 */

import type { ExtensionAPI, Theme } from "@earendil-works/pi-coding-agent";
import {
	Markdown,
	type MarkdownTheme,
	Text,
	truncateToWidth,
	visibleWidth,
	wrapTextWithAnsi,
} from "@earendil-works/pi-tui";

interface Language {
	icon: string;
	name: string;
}

const LANGUAGES: Record<string, Language> = {
	bash: { icon: "", name: "Shell" },
	c: { icon: "", name: "C" },
	cpp: { icon: "", name: "C++" },
	css: { icon: "", name: "CSS" },
	diff: { icon: "", name: "Diff" },
	go: { icon: "", name: "Go" },
	html: { icon: "", name: "HTML" },
	java: { icon: "", name: "Java" },
	javascript: { icon: "", name: "JavaScript" },
	js: { icon: "", name: "JavaScript" },
	json: { icon: "", name: "JSON" },
	jsx: { icon: "", name: "JavaScript JSX" },
	kotlin: { icon: "", name: "Kotlin" },
	markdown: { icon: "", name: "Markdown" },
	md: { icon: "", name: "Markdown" },
	plaintext: { icon: "󰈙", name: "Text" },
	py: { icon: "", name: "Python" },
	python: { icon: "", name: "Python" },
	rust: { icon: "", name: "Rust" },
	rs: { icon: "", name: "Rust" },
	sh: { icon: "", name: "Shell" },
	shell: { icon: "", name: "Shell" },
	sql: { icon: "", name: "SQL" },
	text: { icon: "󰈙", name: "Text" },
	toml: { icon: "", name: "TOML" },
	ts: { icon: "", name: "TypeScript" },
	tsx: { icon: "", name: "TypeScript JSX" },
	typescript: { icon: "", name: "TypeScript" },
	xml: { icon: "󰗀", name: "XML" },
	yaml: { icon: "", name: "YAML" },
	yml: { icon: "", name: "YAML" },
};

const CALLOUTS = {
	PROMPT: { icon: "󰍡", title: "Prompt", color: "accent" },
	NOTE: { icon: "󰋽", title: "Note", color: "accent" },
	TIP: { icon: "󰌶", title: "Tip", color: "success" },
	IMPORTANT: { icon: "󰅾", title: "Important", color: "accent" },
	WARNING: { icon: "", title: "Warning", color: "warning" },
	CAUTION: { icon: "", title: "Caution", color: "error" },
} as const;

const ANSI_RE = /\x1b(?:\[[0-?]*[ -/]*[@-~]|\](?:[^\x07\x1b]|\x1b(?!\\))*(?:\x07|\x1b\\))/g;
const FENCE_RE = /^(\s*)```([^`]*)\s*$/;
const PROSE_WIDTH = 96;

type UiTheme = Pick<Theme, "bg" | "bold" | "fg">;
type CalloutName = keyof typeof CALLOUTS;
type RenderToken = (
	this: Markdown,
	token: MarkdownToken,
	width: number,
	nextTokenType?: string,
	styleContext?: unknown,
) => string[];

interface MarkdownToken {
	type: string;
	depth?: number;
	raw?: string;
	header?: Array<{ tokens?: unknown[]; text?: string }>;
	rows?: Array<Array<{ tokens?: unknown[]; text?: string }>>;
}

interface InternalMarkdown extends Markdown {
	theme: MarkdownTheme;
	renderInlineTokens(tokens: unknown[], styleContext?: unknown): string;
}

interface MarkdownPrototype {
	render: typeof Markdown.prototype.render;
	renderToken: RenderToken;
}

interface Patch {
	restore(): void;
}

function stripAnsi(text: string): string {
	return text.replace(ANSI_RE, "");
}

function languageFor(info: string): Language {
	const id = info.trim().split(/[\s,]/, 1)[0]?.toLowerCase() ?? "";
	if (!id) return { icon: "󰘦", name: "Code" };
	return LANGUAGES[id] ?? { icon: "󰘦", name: id };
}

function fill(text: string, width: number): string {
	const fitted = truncateToWidth(text, Math.max(1, width), "");
	return fitted + " ".repeat(Math.max(0, width - visibleWidth(fitted)));
}

function removeVisiblePrefix(text: string, count: number): string {
	let removed = 0;
	let out = "";
	for (let index = 0; index < text.length; ) {
		if (text[index] === "\x1b") {
			ANSI_RE.lastIndex = index;
			const match = ANSI_RE.exec(text);
			if (match?.index === index) {
				out += match[0];
				index += match[0].length;
				continue;
			}
		}
		const point = text.codePointAt(index);
		if (point === undefined) break;
		const char = String.fromCodePoint(point);
		if (removed >= count) out += char;
		else removed += visibleWidth(char);
		index += char.length;
	}
	ANSI_RE.lastIndex = 0;
	return out;
}

function codeBlockCards(lines: string[], width: number, theme: UiTheme): string[] {
	if (width < 8) return lines;
	const out: string[] = [];
	let inBlock = false;
	let fenceIndent = "";

	for (const line of lines) {
		const plain = stripAnsi(line).trimEnd();
		const fence = FENCE_RE.exec(plain);
		if (!inBlock && fence) {
			inBlock = true;
			fenceIndent = fence[1];
			const language = languageFor(fence[2]);
			const label = theme.fg("warning", `${language.icon} ${language.name}`);
			out.push(theme.bg("customMessageBg", fill(`${fenceIndent}  ${label}`, width)));
			out.push(theme.bg("customMessageBg", " ".repeat(width)));
			continue;
		}
		if (inBlock && fence && fence[1] === fenceIndent && fence[2].trim() === "") {
			out.push(theme.bg("customMessageBg", " ".repeat(width)));
			inBlock = false;
			fenceIndent = "";
			continue;
		}
		out.push(inBlock ? theme.bg("customMessageBg", fill(` ${line}`, width)) : line);
	}
	return out;
}

function calloutName(token: MarkdownToken): CalloutName | undefined {
	const match = token.raw?.match(/^\s*>\s*\[!([A-Z]+)]/i);
	const name = match?.[1]?.toUpperCase() as CalloutName | undefined;
	return name && name in CALLOUTS ? name : undefined;
}

function calloutCard(lines: string[], width: number, name: CalloutName, theme: UiTheme): string[] {
	const spec = CALLOUTS[name];
	const color = spec.color;
	const content = lines.map((line) => removeVisiblePrefix(line.trimEnd(), 2));
	const marker = new RegExp(`^\\[!${name}]\\s*`, "i");
	if (content.length) {
		const plain = stripAnsi(content[0]);
		const rest = plain.replace(marker, "");
		if (rest === plain || !rest) content.shift();
		else content[0] = rest;
	}
	while (content.at(-1) !== undefined && stripAnsi(content.at(-1) ?? "").trim() === "") content.pop();

	if (width < 20) {
		return [theme.fg(color, `${spec.title}:`), ...content];
	}
	const label = ` ${spec.icon} ${spec.title} `;
	const top = `╭─${label}${"─".repeat(Math.max(0, width - visibleWidth(label) - 3))}╮`;
	const bodyWidth = width - 2;
	const body = content.length ? content : [""];
	return [
		theme.fg(color, top),
		...body.map(
			(line) =>
				theme.fg(color, "│") +
				theme.bg("customMessageBg", fill(` ${line}`, bodyWidth)) +
				theme.fg(color, "│"),
		),
		theme.fg(color, `╰${"─".repeat(width - 2)}╯`),
	];
}

function quietTable(lines: string[], width: number, theme: UiTheme): string[] {
	const rows: string[] = [];
	let headerSeen = false;
	for (const line of lines) {
		const plain = stripAnsi(line).trimEnd();
		if (/^[┌└].*[┐┘]$/.test(plain)) continue;
		if (/^├.*┤$/.test(plain)) {
			const tableWidth = Math.min(width, Math.max(1, visibleWidth(plain) - 2));
			rows.push(theme.fg("dim", "─".repeat(tableWidth)));
			continue;
		}
		if (plain.startsWith("│") && plain.endsWith("│")) {
			const converted = line.replaceAll("│", " ").trimEnd();
			rows.push(headerSeen ? converted : theme.bold(converted));
			headerSeen = true;
			continue;
		}
		rows.push(line);
	}
	return rows;
}

function stackedTable(
	markdown: InternalMarkdown,
	token: MarkdownToken,
	styleContext: unknown,
): string[] | undefined {
	if (!token.header?.length || !token.rows?.length) return undefined;
	const headers = token.header.map((cell) =>
		markdown.renderInlineTokens(cell.tokens ?? [], styleContext).trim(),
	);
	const lines: string[] = [];
	for (const row of token.rows) {
		for (let index = 0; index < headers.length; index++) {
			const value = markdown.renderInlineTokens(row[index]?.tokens ?? [], styleContext).trim();
			lines.push(`${headers[index]}: ${value}`);
		}
		lines.push("");
	}
	return lines;
}

function listMarker(marker: string): string {
	if (/^- \[[xX]] /.test(marker)) return "• [✓] ";
	if (/^- \[ ] /.test(marker)) return "• [○] ";
	if (marker === "- ") return "• ";
	return marker;
}

function styleHeading(
	markdown: InternalMarkdown,
	original: RenderToken,
	token: MarkdownToken,
	width: number,
	nextTokenType: string | undefined,
	styleContext: unknown,
	theme: UiTheme,
): string[] {
	const level = token.depth ?? 1;
	const previous = markdown.theme;
	markdown.theme = {
		...previous,
		heading: (text) => theme.fg(level === 1 ? "accent" : "text", text),
	};
	let lines: string[];
	try {
		lines = original.call(markdown, token, width, nextTokenType, styleContext);
	} finally {
		markdown.theme = previous;
	}
	if (!lines.length) return lines;
	if (level >= 3) lines[0] = removeVisiblePrefix(lines[0], level + 1);
	const heading = lines[0].trimEnd();
	if (level === 1 || level === 3) {
		const rule = level === 1 ? "═" : "─";
		lines.splice(1, 0, theme.fg(level === 1 ? "accent" : "dim", rule.repeat(Math.min(width, visibleWidth(heading)))));
	}
	return lines;
}

export function installMarkdownStyle(theme: UiTheme): Patch {
	const prototype = Markdown.prototype as unknown as MarkdownPrototype;
	const originalRender = prototype.render;
	const originalRenderToken = prototype.renderToken;

	const patchedRenderToken: RenderToken = function (token, width, nextTokenType, styleContext) {
		const markdown = this as InternalMarkdown;
		if (token.type === "heading") {
			return styleHeading(markdown, originalRenderToken, token, width, nextTokenType, styleContext, theme);
		}
		if (token.type === "paragraph") {
			const proseWidth = Math.min(width, PROSE_WIDTH);
			return originalRenderToken
				.call(this, token, proseWidth, nextTokenType, styleContext)
				.flatMap((line) => wrapTextWithAnsi(line, proseWidth));
		}
		if (token.type === "blockquote") {
			const previous = markdown.theme;
			markdown.theme = { ...previous, italic: (text) => text };
			let lines: string[];
			try {
				lines = originalRenderToken.call(this, token, width, nextTokenType, styleContext);
			} finally {
				markdown.theme = previous;
			}
			const name = calloutName(token);
			return name ? calloutCard(lines, width, name, theme) : lines;
		}
		if (token.type === "table") {
			if (width < 50) {
				const stacked = stackedTable(markdown, token, styleContext);
				if (stacked) return stacked;
			}
			return quietTable(
				originalRenderToken.call(this, token, width, nextTokenType, styleContext),
				width,
				theme,
			);
		}
		return originalRenderToken.call(this, token, width, nextTokenType, styleContext);
	};

	const patchedRender: typeof Markdown.prototype.render = function (width: number): string[] {
		const markdown = this as InternalMarkdown;
		const previous = markdown.theme;
		markdown.theme = {
			...previous,
			code: (text) => theme.bg("selectedBg", previous.code(text)),
			listBullet: (marker) => previous.listBullet(listMarker(marker)),
			quoteBorder: (text) => theme.fg("dim", text),
		};
		let lines: string[];
		try {
			lines = originalRender.call(this, width);
		} finally {
			markdown.theme = previous;
		}
		return codeBlockCards(lines, width, theme);
	};

	prototype.renderToken = patchedRenderToken;
	prototype.render = patchedRender;

	return {
		restore() {
			if (prototype.render === patchedRender) prototype.render = originalRender;
			if (prototype.renderToken === patchedRenderToken) prototype.renderToken = originalRenderToken;
		},
	};
}

interface Receipt {
	files: number;
	adds: number;
	dels: number;
	checks: number;
	failedChecks: number;
	subagents: number;
	durationMs: number;
	cost: number;
}

function receiptText(receipt: Receipt): string {
	const parts: string[] = [];
	if (receipt.files) parts.push(`${receipt.files} ${receipt.files === 1 ? "file" : "files"}`);
	if (receipt.adds || receipt.dels) parts.push(`+${receipt.adds} -${receipt.dels}`);
	if (receipt.checks) {
		const label = receipt.checks === 1 ? "check" : "checks";
		parts.push(receipt.failedChecks ? `✗ ${receipt.failedChecks}/${receipt.checks} ${label}` : `✓ ${receipt.checks} ${label}`);
	}
	if (receipt.subagents) parts.push(`${receipt.subagents} ${receipt.subagents === 1 ? "subagent" : "subagents"}`);
	parts.push(`${Math.max(1, Math.round(receipt.durationMs / 1000))}s`);
	if (receipt.cost > 0) parts.push(`$${receipt.cost.toFixed(2)}`);
	return parts.join(" · ");
}

function sessionCost(branch: readonly unknown[]): number {
	let total = 0;
	const subagentCosts = new Map<string, number>();
	for (const [index, raw] of branch.entries()) {
		const entry = raw as {
			type?: string;
			message?: {
				role?: string;
				toolName?: string;
				usage?: { cost?: { total?: number } };
				details?: { runId?: string; asyncId?: string; totalCost?: { costUsd?: number } };
			};
		};
		if (entry.type !== "message" || !entry.message) continue;
		if (entry.message.role === "assistant") total += entry.message.usage?.cost?.total ?? 0;
		if (entry.message.role === "toolResult" && entry.message.toolName === "subagent") {
			const details = entry.message.details;
			const id = details?.runId ?? details?.asyncId ?? String(index);
			subagentCosts.set(id, Math.max(subagentCosts.get(id) ?? 0, details?.totalCost?.costUsd ?? 0));
		}
	}
	return total + [...subagentCosts.values()].reduce((sum, value) => sum + value, 0);
}

function patchStats(receipt: Receipt, patch: string | undefined): void {
	if (!patch) return;
	let inHunk = false;
	for (const line of patch.split("\n")) {
		if (line.startsWith("diff ")) {
			inHunk = false;
			continue;
		}
		if (line.startsWith("@@")) {
			inHunk = true;
			continue;
		}
		if (!inHunk) continue;
		if (line.startsWith("+")) receipt.adds++;
		else if (line.startsWith("-")) receipt.dels++;
	}
}

export default function (pi: ExtensionAPI) {
	let enabled = true;
	let patch: Patch | undefined;
	let receipt: Receipt | undefined;
	let files = new Set<string>();
	let startCost = 0;
	const toolArgs = new Map<string, { path?: string; command?: string }>();

	pi.registerEntryRenderer<Receipt>("completion-receipt", (entry, _options, theme) => {
		const text = receiptText(entry.data as Receipt);
		const color = (entry.data as Receipt).failedChecks ? "warning" : "dim";
		return new Text(theme.fg(color, text), 0, 0);
	});

	pi.on("session_start", async (_event, ctx) => {
		if (ctx.mode === "tui" && !patch) patch = installMarkdownStyle(ctx.ui.theme);
	});

	pi.on("agent_start", async (_event, ctx) => {
		if (receipt) return;
		files = new Set();
		startCost = sessionCost(ctx.sessionManager.getBranch());
		receipt = { files: 0, adds: 0, dels: 0, checks: 0, failedChecks: 0, subagents: 0, durationMs: Date.now(), cost: 0 };
	});

	pi.on("tool_execution_start", async (event) => {
		toolArgs.set(event.toolCallId, event.args as { path?: string; command?: string });
	});

	pi.on("tool_execution_end", async (event) => {
		const args = toolArgs.get(event.toolCallId) ?? {};
		toolArgs.delete(event.toolCallId);
		if (!receipt) return;
		const tool = event.toolName;
		if (!event.isError && (tool === "edit" || tool === "write") && args.path) files.add(args.path);
		if (!event.isError && tool === "edit") {
			patchStats(receipt, (event.result.details as { patch?: string } | undefined)?.patch);
		}
		if (tool === "bash" && /(?:^|\s)(?:test|lint|typecheck|check|build)(?:\s|$)|\b(?:pytest|vitest|jest|tsc|cargo test|go test)\b/i.test(args.command ?? "")) {
			receipt.checks++;
			if (event.isError) receipt.failedChecks++;
		}
		if (/sub-?agent/i.test(tool)) receipt.subagents++;
	});

	pi.on("agent_settled", async (_event, ctx) => {
		if (!receipt) return;
		receipt.files = files.size;
		receipt.durationMs = Date.now() - receipt.durationMs;
		receipt.cost = Math.max(0, sessionCost(ctx.sessionManager.getBranch()) - startCost);
		if (receipt.files || receipt.checks || receipt.subagents || receipt.durationMs >= 30_000) {
			pi.appendEntry("completion-receipt", receipt);
		}
		receipt = undefined;
	});

	pi.on("session_shutdown", async () => {
		patch?.restore();
		patch = undefined;
		receipt = undefined;
		toolArgs.clear();
	});

	pi.registerCommand("markdown-style", {
		description: "Toggle editorial Markdown output (on|off, default on)",
		handler: async (args, ctx) => {
			const arg = args.trim().toLowerCase();
			if (arg === "on") enabled = true;
			else if (arg === "off") enabled = false;
			else enabled = !enabled;
			if (!enabled) {
				patch?.restore();
				patch = undefined;
			} else if (!patch && ctx.mode === "tui") {
				patch = installMarkdownStyle(ctx.ui.theme);
			}
			ctx.ui.notify(`Editorial Markdown ${enabled ? "on" : "off"}; applies on next render`, "info");
		},
	});
}

if (import.meta.main) {
	const { deepStrictEqual: equal, match, ok } = await import("node:assert");
	const identity = (text: string) => text;
	const markdownTheme: MarkdownTheme = {
		heading: identity,
		link: identity,
		linkUrl: identity,
		code: identity,
		codeBlock: identity,
		codeBlockBorder: identity,
		quote: identity,
		quoteBorder: identity,
		hr: identity,
		listBullet: identity,
		bold: identity,
		italic: identity,
		strikethrough: identity,
		underline: identity,
	};
	const uiTheme = {
		fg: (_color: string, text: string) => text,
		bg: (_color: string, text: string) => text,
		bold: identity,
	} as unknown as UiTheme;
	const prototype = Markdown.prototype as unknown as MarkdownPrototype;
	const originalRender = prototype.render;
	const originalRenderToken = prototype.renderToken;
	const installed = installMarkdownStyle(uiTheme);
	try {
		const source = [
			"# Result",
			"",
			"### Detail",
			"",
			"Use `RoleGrant.resolve()`.",
			"",
			"> [!WARNING]",
			"> Check grants.",
			"",
			"| Model | Context |",
			"|---|---|",
			"| GPT | 1M |",
			"",
			"```text",
			"root",
			"└── child",
			"```",
		].join("\n");
		const lines = new Markdown(source, 0, 0, markdownTheme).render(60);
		const plain = lines.map((line) => stripAnsi(line).trimEnd()).join("\n");
		match(plain, /Result\n═+/);
		ok(!plain.includes("### Detail"));
		match(plain, /Detail\n─+/);
		match(plain, /Warning/);
		ok(!plain.includes("[!WARNING]"));
		ok(!plain.includes("┌"));
		match(plain, /󰈙 Text/);
		ok(!plain.includes("```text"));

		const proseLines = new Markdown("word ".repeat(30), 0, 0, markdownTheme)
			.render(120)
			.map((line) => stripAnsi(line).trimEnd())
			.filter(Boolean);
		ok(proseLines.length > 1);
		ok(proseLines.every((line) => visibleWidth(line) <= PROSE_WIDTH));

		const narrowTable = new Markdown("| Model | Context |\n|---|---|\n| GPT | 1M |", 0, 0, markdownTheme)
			.render(40)
			.map((line) => stripAnsi(line).trimEnd())
			.join("\n");
		match(narrowTable, /Model: GPT/);
		match(narrowTable, /Context: 1M/);

		for (const [name, spec] of Object.entries(CALLOUTS)) {
			const callout = new Markdown(`> [!${name}]\n> Content`, 0, 0, markdownTheme)
				.render(60)
				.map((line) => stripAnsi(line).trimEnd())
				.join("\n");
			match(callout, new RegExp(spec.title));
			ok(!callout.includes(`[!${name}]`));
		}
		const unknownCallout = new Markdown("> [!UNKNOWN]\n> Content", 0, 0, markdownTheme)
			.render(60)
			.map((line) => stripAnsi(line).trimEnd())
			.join("\n");
		ok(unknownCallout.includes("[!UNKNOWN]"));
	} finally {
		installed.restore();
	}
	equal(prototype.render, originalRender);
	equal(prototype.renderToken, originalRenderToken);
	equal(listMarker("- [x] "), "• [✓] ");
	equal(listMarker("- [ ] "), "• [○] ");
	equal(listMarker("- "), "• ");
	equal(receiptText({ files: 2, adds: 4, dels: 1, checks: 1, failedChecks: 0, subagents: 0, durationMs: 2400, cost: 0.12 }), "2 files · +4 -1 · ✓ 1 check · 2s · $0.12");
	const patchReceipt: Receipt = { files: 0, adds: 0, dels: 0, checks: 0, failedChecks: 0, subagents: 0, durationMs: 0, cost: 0 };
	patchStats(patchReceipt, "--- a/file\n+++ b/file\n@@ -1 +1 @@\n--old\n++new");
	equal({ adds: patchReceipt.adds, dels: patchReceipt.dels }, { adds: 1, dels: 1 });
	console.log("markdown-output.ts self-check: ok");
}
