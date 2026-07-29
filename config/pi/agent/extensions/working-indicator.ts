/**
 * Per-state working indicator for pi.
 *
 * Replaces the single generic "Working …" spinner with a state-aware inline
 * indicator: a distinct animation + verb for each thing pi is doing.
 *
 *   Thinking     ✶ ✷ ✸ ✹ ✺
 *   Processing   ⠁ ⠂ ⠄ ⡀ ⢀ ⠠ ⠐ ⠈
 *   Using tools  󰪞 󰪟 󰪠 󰪡 󰪢 󰪣 󰪤 󰪥
 *   Subagent     ◌ ◎ ◉ ● ◉ ◎
 *
 * State is derived from lifecycle events:
 *   - tool_execution_start/end  → tools (or subagent, by tool-name pattern)
 *   - message_update thinking_* → thinking
 *   - message_update text_*     → processing
 *   - turn_start                → processing (default)
 *
 * Tool execution outranks streaming: while any tool runs we show tools /
 * subagent, otherwise we reflect the current stream (thinking vs processing).
 *
 * Placement: ~/.pi/agent/extensions/working-indicator.ts (auto-discovered).
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

type State = "thinking" | "processing" | "tools" | "subagent";

// Tools whose name suggests they dispatch a sub-agent. None of pi's built-ins
// match; this lights up automatically for custom agent/task tools.
const SUBAGENT_RE = /(sub-?agent|agent|task|dispatch|spawn|delegate)/i;

interface Spec {
	frames: string[];
	intervalMs: number;
	verb: string;
	color: string; // theme color token
}

const SPECS: Record<State, Spec> = {
	thinking: {
		frames: ["✶", "✷", "✸", "✹", "✺"],
		intervalMs: 120,
		verb: "Thinking",
		color: "warning",
	},
	processing: {
		frames: ["⠁", "⠂", "⠄", "⡀", "⢀", "⠠", "⠐", "⠈"],
		intervalMs: 80,
		verb: "Processing",
		color: "accent",
	},
	tools: {
		frames: ["󰪞", "󰪟", "󰪠", "󰪡", "󰪢", "󰪣", "󰪤", "󰪥"],
		intervalMs: 90,
		verb: "Using tools",
		color: "accent",
	},
	subagent: {
		frames: ["◌", "◎", "◉", "●", "◉", "◎"],
		intervalMs: 140,
		verb: "Running subagent",
		color: "success",
	},
};

export default function (pi: ExtensionAPI) {
	// Active tool executions, keyed by id → whether it's a subagent-ish tool.
	const activeTools = new Map<string, boolean>();
	// Latest streaming state (used when no tools are running).
	let streamState: State = "processing";
	let current: State | null = null;
	// Colored frames, built once the theme is available.
	let colored: Record<State, string[]> | null = null;
	// Colored verb text per state (so the message isn't rendered dim).
	let coloredVerb: Record<State, string> | null = null;
	// UI handle captured at session start (UI methods live on ctx.ui).
	let ui:
		| {
				setWorkingIndicator(o?: { frames?: string[]; intervalMs?: number }): void;
				setWorkingMessage(m?: string): void;
		  }
		| null = null;

	// Applies the indicator for a state, coalescing redundant updates.
	function apply(next: State): void {
		if (next === current || !colored || !ui) return;
		current = next;
		const spec = SPECS[next];
		ui.setWorkingIndicator({ frames: colored[next], intervalMs: spec.intervalMs });
		ui.setWorkingMessage(coloredVerb ? coloredVerb[next] : ` ${spec.verb}…`);
	}

	// Effective state: tools/subagent outrank streaming.
	function refresh(): void {
		if (activeTools.size > 0) {
			apply([...activeTools.values()].some(Boolean) ? "subagent" : "tools");
		} else {
			apply(streamState);
		}
	}

	pi.on("session_start", async (_event, ctx) => {
		ui = ctx.ui;
		const theme = ctx.ui.theme;
		colored = {
			thinking: [],
			processing: [],
			tools: [],
			subagent: [],
		};
		coloredVerb = { thinking: "", processing: "", tools: "", subagent: "" };
		for (const key of Object.keys(SPECS) as State[]) {
			const spec = SPECS[key];
			colored[key] = spec.frames.map((f) => theme.fg(spec.color as never, f));
			coloredVerb[key] = theme.fg(spec.color as never, ` ${spec.verb}…`);
		}
		// Prime a sensible default.
		current = null;
		streamState = "processing";
		refresh();
	});

	pi.on("turn_start", async () => {
		streamState = "processing";
		refresh();
	});

	pi.on("message_update", async (event) => {
		const t = event.assistantMessageEvent?.type;
		if (t === "thinking_start" || t === "thinking_delta") {
			streamState = "thinking";
		} else if (t === "text_start" || t === "text_delta") {
			streamState = "processing";
		}
		refresh();
	});

	pi.on("tool_execution_start", async (event) => {
		activeTools.set(event.toolCallId, SUBAGENT_RE.test(event.toolName));
		refresh();
	});

	pi.on("tool_execution_end", async (event) => {
		activeTools.delete(event.toolCallId);
		// After a tool finishes we're generally processing the result.
		if (activeTools.size === 0) streamState = "processing";
		refresh();
	});
}
