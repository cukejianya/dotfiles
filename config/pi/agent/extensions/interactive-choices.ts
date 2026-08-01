import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

interface ChoiceItem {
	label: string;
	checked: boolean;
}

const MAX_VISIBLE = 12;

function normalizeOptions(options: string[]): string[] {
	const seen = new Set<string>();
	const out: string[] = [];
	for (const raw of options) {
		const value = String(raw ?? "").trim();
		if (!value || seen.has(value)) continue;
		seen.add(value);
		out.push(value);
	}
	return out;
}

async function pickMany(
	ctx: ExtensionContext,
	title: string,
	options: string[],
	preselected: string[] = [],
	emitMode?: (mode: "normal" | "insert") => void,
): Promise<string[] | null> {
	if (ctx.mode !== "tui" || !ctx.hasUI) return null;
	const selected = new Set(preselected);
	const items: ChoiceItem[] = options.map((label) => ({ label, checked: selected.has(label) }));
	if (!items.length) return [];

	return ctx.ui.custom<string[] | null>((tui, theme, keybindings, done) => {
		let filter = "";
		let cursor = 0;
		let top = 0;
		let mode: "normal" | "insert" = "normal";
		// Drive the shared statusline mode indicator (pi-vim:mode-change).
		const setMode = (next: "normal" | "insert") => {
			mode = next;
			emitMode?.(next);
			refresh();
		};
		emitMode?.("normal");

		const filtered = (): ChoiceItem[] => {
			if (!filter) return items;
			const f = filter.toLowerCase();
			return items.filter((i) => i.label.toLowerCase().includes(f));
		};

		const clamp = () => {
			const view = filtered();
			if (view.length === 0) {
				cursor = 0;
				top = 0;
				return;
			}
			cursor = Math.max(0, Math.min(cursor, view.length - 1));
			if (cursor < top) top = cursor;
			if (cursor >= top + MAX_VISIBLE) top = cursor - MAX_VISIBLE + 1;
			top = Math.max(0, top);
		};

		const refresh = () => {
			clamp();
			tui.requestRender();
		};

		function render(width: number): string[] {
			const safeWidth = Math.max(10, width);
			const view = filtered();
			const checkedCount = items.filter((i) => i.checked).length;
			const end = Math.min(top + MAX_VISIBLE, view.length);
			const lines: string[] = [];

			lines.push(
				theme.fg("accent", theme.bold(`✻ ${title} `)) +
					theme.fg("muted", `(${checkedCount}/${items.length} selected)`),
			);
			lines.push(
				theme.fg("muted", "  filter: ") +
					(filter
						? theme.fg("text", filter) +
							(mode === "insert" ? theme.fg("dim", "▏") : "") +
							theme.fg("dim", ` — ${view.length} match`)
						: theme.fg("dim", mode === "insert" ? "type to filter" : "i to filter")),
			);
			lines.push("");

			if (view.length === 0) {
				lines.push(theme.fg("warning", "  no matches"));
			} else {
				for (let i = top; i < end; i++) {
					const it = view[i];
					const isCur = i === cursor;
					const pointer = isCur ? theme.fg("accent", "> ") : "  ";
					const box = it.checked ? theme.fg("success", "[x]") : theme.fg("dim", "[ ]");
					const name = isCur ? theme.bold(it.label) : it.label;
					lines.push(`${pointer}${box} ${name}`);
				}
			}

			lines.push("");
			const help =
				mode === "insert"
					? "type to filter • Esc normal mode • Enter confirm"
					: "j/k move • space toggle • l select • h unselect • i filter • Enter confirm • q cancel";
			lines.push(theme.fg("dim", help));
			lines.push(theme.fg("accent", "─".repeat(Math.max(1, Math.min(80, safeWidth)))));
			return lines;
		}

		const setChecked = (value: boolean) => {
			const view = filtered();
			if (view[cursor]) view[cursor].checked = value;
			refresh();
		};

		function handleInput(data: string): void {
			// Enter always confirms; the cursor keys always move (both modes).
			if (keybindings.matches(data, "tui.select.confirm")) {
				return done(items.filter((i) => i.checked).map((i) => i.label));
			}
			if (keybindings.matches(data, "tui.select.up")) {
				cursor -= 1;
				return refresh();
			}
			if (keybindings.matches(data, "tui.select.down")) {
				cursor += 1;
				return refresh();
			}

			if (mode === "insert") {
				// Esc returns to normal mode (keeps the current filter).
				if (keybindings.matches(data, "tui.select.cancel")) {
					return setMode("normal");
				}
				if (data === "\x7f" || data === "\b") {
					filter = filter.slice(0, -1);
					cursor = 0;
					top = 0;
					return refresh();
				}
				if (data.length === 1 && data >= " " && data.charCodeAt(0) < 127) {
					filter += data;
					cursor = 0;
					top = 0;
					return refresh();
				}
				return;
			}

			// NORMAL mode
			if (data === "q") return done(null);
			if (data === "i") return setMode("insert");
			if (data === "j") {
				cursor += 1;
				return refresh();
			}
			if (data === "k") {
				cursor -= 1;
				return refresh();
			}
			if (data === " ") {
				const view = filtered();
				if (view[cursor]) view[cursor].checked = !view[cursor].checked;
				return refresh();
			}
			if (data === "l") return setChecked(true);
			if (data === "h") return setChecked(false);
		}

		return { render, invalidate: () => {}, handleInput };
	});
}

export default function (pi: ExtensionAPI) {
	// Remember pi-vim's real editor mode so we can restore the statusline
	// indicator after the picker closes. Ignore our own emissions while active.
	let lastEditorMode = "insert";
	let pickerActive = false;
	pi.events.on("pi-vim:mode-change", (data) => {
		if (pickerActive) return;
		const m = (data as { mode?: string })?.mode;
		if (typeof m === "string") lastEditorMode = m.toLowerCase();
	});
	const emitMode = (mode: "normal" | "insert") => {
		pi.events.emit("pi-vim:mode-change", { mode });
	};

	pi.on("before_agent_start", async (event) => {
		return {
			systemPrompt:
				event.systemPrompt +
				"\n\nWhen you need the user to choose from explicit options, do not ask as free text. Use the ask_user_choice tool instead. For one option use single-select mode; for multiple options use multi-select mode.",
		};
	});

	pi.registerTool({
		name: "ask_user_choice",
		label: "Ask User Choice",
		description:
			"Ask the user to choose from explicit options via UI selection. Supports single-select and multi-select.",
		promptSnippet:
			"Present explicit choices to the user and return the selected option(s) instead of asking for free-text replies.",
		promptGuidelines: [
			"Use ask_user_choice whenever you need the user to pick from explicit options.",
			"Set allowMultiple=true when multiple selections are allowed.",
		],
		parameters: Type.Object({
			question: Type.String({ description: "Question shown to the user" }),
			options: Type.Array(Type.String(), { description: "Selectable options" }),
			allowMultiple: Type.Optional(
				Type.Boolean({ description: "Allow selecting multiple options" }),
			),
			preselected: Type.Optional(
				Type.Array(Type.String(), { description: "Options preselected in multi-select mode" }),
			),
		}),
		async execute(_toolCallId, input, _signal, _onUpdate, ctx) {
			const options = normalizeOptions(input.options ?? []);
			if (!options.length) {
				return {
					isError: true,
					content: [{ type: "text", text: "No valid options were provided." }],
				};
			}

			if (ctx.mode !== "tui" || !ctx.hasUI) {
				return {
					content: [
						{ type: "text", text: `Interactive picker unavailable. Options:\n- ${options.join("\n- ")}` },
					],
					details: { cancelled: true, selected: [] },
				};
			}

			if (input.allowMultiple) {
				pickerActive = true;
				let selected: string[] | null;
				try {
					selected = await pickMany(
						ctx,
						input.question?.trim() || "Select options",
						options,
						input.preselected ?? [],
						emitMode,
					);
				} finally {
					pickerActive = false;
					// Restore the editor's real mode in the statusline.
					emitMode(lastEditorMode === "normal" ? "normal" : "insert");
				}
				if (selected === null) {
					return {
						content: [{ type: "text", text: "User cancelled selection." }],
						details: { cancelled: true, selected: [] },
					};
				}
				return {
					content: [
						{
							type: "text",
							text: selected.length
								? `User selected ${selected.length} option(s):\n- ${selected.join("\n- ")}`
								: "User selected no options.",
						},
					],
					details: { cancelled: false, selected },
				};
			}

			const picked = await ctx.ui.select(input.question?.trim() || "Select an option", options);
			if (!picked) {
				return {
					content: [{ type: "text", text: "User cancelled selection." }],
					details: { cancelled: true, selected: [] },
				};
			}
			return {
				content: [{ type: "text", text: `User selected: ${picked}` }],
				details: { cancelled: false, selected: [picked] },
			};
		},
	});

	pi.registerCommand("choice-mode", {
		description: "Explain how option questions are handled (single-select vs multi-select)",
		handler: async (_args, ctx) => {
			ctx.ui.notify(
				"Enabled: assistant should use ask_user_choice for explicit options (single-select for one choice, checklist-style multi-select for multiple).",
				"info",
			);
		},
	});
}
