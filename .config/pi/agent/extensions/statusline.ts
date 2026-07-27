/**
 * Statusline footer for pi — model agnostic.
 *
 * A port of the Claude Code `statusline-command.sh` single-line, left/right
 * split status line. Renders:
 *   left:  git branch · context usage bar · cost
 *   right: status icon · model id
 *
 * Unlike the Claude Code shell script (which reads JSON from stdin), pi drives
 * the footer through a live render callback, so everything is reactive.
 *
 * Placement: ~/.pi/agent/extensions/statusline.ts (auto-discovered, /reload-able)
 */

import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

// Brand name shown before the model, keyed by provider id.
const PROVIDER_BRAND: Record<string, string> = {
	anthropic: "Claude",
	openai: "OpenAI",
	google: "Gemini",
	"google-vertex": "Gemini",
	xai: "Grok",
	deepseek: "DeepSeek",
	mistral: "Mistral",
};

// Token-level display overrides (case-insensitive), applied per id token.
const WORD_OVERRIDES: Record<string, string> = {
	gpt: "Chat GPT",
};

const cap = (s: string) =>
	s ? (WORD_OVERRIDES[s.toLowerCase()] ?? s[0].toUpperCase() + s.slice(1)) : s;

/**
 * Prettify a model id into "Brand | Family Version".
 *   claude-opus-4-8        → Claude | Opus 4.8
 *   claude-3-5-sonnet      → Claude | 3.5 Sonnet
 *   gpt-4o (openai)        → OpenAI | Gpt 4o
 */
function prettyModel(id: string | undefined, provider: string | undefined): string {
	if (!id) return "no-model";
	const brand = provider ? (PROVIDER_BRAND[provider] ?? cap(provider)) : "";
	// Split id into tokens, collapsing consecutive numeric tokens into a
	// dotted version (4, 8 → 4.8).
	const tokens = id.split(/[-_]/);
	const out: string[] = [];
	let nums: string[] = [];
	const flush = () => {
		if (nums.length) {
			out.push(nums.join("."));
			nums = [];
		}
	};
	for (const t of tokens) {
		if (/^\d+$/.test(t)) nums.push(t);
		else {
			flush();
			out.push(cap(t));
		}
	}
	flush();
	// Drop a leading token that duplicates the brand (e.g. "Claude").
	if (out.length > 1 && brand && out[0].toLowerCase() === brand.toLowerCase()) {
		out.shift();
	}
	const right = out.join(" ");
	return brand ? `${brand} | ${right}` : right;
}

// Input-box chrome (session name, border color, ➜ prompt) is owned by the
// custom-input extension. This extension only renders the footer status line.

export default function (pi: ExtensionAPI) {
	// Track whether pi is busy so we can flip the status icon.
	let busy = false;
	// Captured from the footer factory so turn events can force a re-render.
	let activeTui: { requestRender(): void } | undefined;

	// Spinner animation for the busy state. Braille dots cycle while pi works;
	// a timer ticks the frame and requests re-renders independent of events.
	const SPINNER_FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
	const SPINNER_INTERVAL_MS = 80;
	let spinnerFrame = 0;
	let spinnerTimer: ReturnType<typeof setInterval> | undefined;

	function startSpinner() {
		if (spinnerTimer) return;
		spinnerTimer = setInterval(() => {
			spinnerFrame = (spinnerFrame + 1) % SPINNER_FRAMES.length;
			activeTui?.requestRender();
		}, SPINNER_INTERVAL_MS);
		spinnerTimer.unref?.();
	}

	function stopSpinner() {
		if (spinnerTimer) {
			clearInterval(spinnerTimer);
			spinnerTimer = undefined;
		}
		spinnerFrame = 0;
	}

	// Vim mode, sourced from the pi-vim extension's mode-change events.
	// pi-vim's editor starts in insert mode, so mirror that default.
	let vimMode = "INSERT";
	pi.events.on("pi-vim:mode-change", (data) => {
		const mode = (data as { mode?: string })?.mode;
		if (typeof mode === "string") {
			vimMode = mode.toUpperCase();
			activeTui?.requestRender();
		}
	});

	pi.on("turn_start", async () => {
		busy = true;
		startSpinner();
		activeTui?.requestRender();
	});
	pi.on("turn_end", async () => {
		busy = false;
		stopSpinner();
		activeTui?.requestRender();
	});

	pi.on("session_start", async (_event, ctx) => {
		ctx.ui.setFooter((tui, theme, footerData) => {
			activeTui = tui;
			const unsub = footerData.onBranchChange(() => tui.requestRender());

			return {
				dispose: () => {
					unsub();
					stopSpinner();
					activeTui = undefined;
				},
				invalidate() {},
				render(width: number): string[] {
					const sep = theme.fg("dim", "  ");
					const leftParts: string[] = [];

					// — Vim mode (always shown) —
					let modeColor: "accent" | "warning" | "success";
					switch (vimMode) {
						case "INSERT":
							modeColor = "accent";
							break;
						case "NORMAL":
							modeColor = "success";
							break;
						default: // EX, VISUAL, etc.
							modeColor = "warning";
					}
					leftParts.push(theme.fg(modeColor, vimMode));

					// — Git branch (hidden when not in a repo) —
					const branch = footerData.getGitBranch();
					if (branch) {
						leftParts.push(theme.fg("dim", ` ${branch}`));
					}

					// — Context usage bar (▰▱, 10 segments) —
					const usage = ctx.getContextUsage?.();
					if (usage && usage.percent != null) {
						const pct = Math.round(usage.percent);
						let color: "success" | "warning" | "error" = "success";
						if (pct >= 80) color = "error";
						else if (pct >= 50) color = "warning";

						let filled = Math.floor(pct / 10);
						if (filled > 10) filled = 10;
						const bar = "▰".repeat(filled) + "▱".repeat(10 - filled);
						leftParts.push(theme.fg(color, `${bar} ${pct}%`));
					}

					// — Cost (summed over assistant messages on the branch) —
					let cost = 0;
					for (const e of ctx.sessionManager.getBranch()) {
						if (e.type === "message" && e.message.role === "assistant") {
							cost += (e.message as AssistantMessage).usage.cost.total;
						}
					}
					if (cost > 0) {
						leftParts.push(theme.fg("dim", `$${cost.toFixed(2)}`));
					}

					const left = leftParts.join(sep);

					// — Right side: status icon + model id (model agnostic) —
					// Animated spinner while busy, static check when idle.
					const icon = busy
						? theme.fg("accent", SPINNER_FRAMES[spinnerFrame])
						: theme.fg("success", "\u{F012C}"); // 󰄬 check
					const model = prettyModel(ctx.model?.id, ctx.model?.provider);
					const right = `${icon} ${theme.fg("dim", model)}`;

					const pad = " ".repeat(
						Math.max(1, width - visibleWidth(left) - visibleWidth(right)),
					);
					return [truncateToWidth(left + pad + right, width)];
				},
			};
		});
	});

	pi.on("session_shutdown", async (_event, ctx) => {
		ctx.ui.setFooter(undefined);
	});
}
