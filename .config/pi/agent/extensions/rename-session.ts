/**
 * Exposes session renaming as an LLM-callable tool.
 *
 * Lets the agent set the current session's friendly name (shown in the
 * session selector) via a tool call, in addition to the /rename command.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "@earendil-works/pi-ai";

export default function (pi: ExtensionAPI) {
	// LLM-callable tool
	pi.registerTool({
		name: "rename_session",
		label: "Rename Session",
		description:
			"Set the current pi session's friendly name, shown in the session selector. Use when the user asks to name or rename this session/conversation.",
		promptSnippet: "Rename the current session to a friendly name",
		promptGuidelines: [
			"Use rename_session when the user asks to name or rename the current session/conversation.",
		],
		parameters: Type.Object({
			name: Type.String({ description: "New session name" }),
		}),
		async execute(_toolCallId, params) {
			const name = String(params.name ?? "").trim();
			if (!name) {
				return {
					content: [{ type: "text", text: "Error: name must not be empty." }],
					isError: true,
				};
			}
			pi.setSessionName(name);
			return {
				content: [{ type: "text", text: `Session renamed to: ${name}` }],
				details: { name },
			};
		},
	});

	// Convenience slash command mirroring the tool
	pi.registerCommand("rename", {
		description: "Rename the session (usage: /rename <name>)",
		handler: async (args, ctx) => {
			const name = args.trim();
			if (name) {
				pi.setSessionName(name);
				ctx.ui.notify(`Session renamed: ${name}`, "info");
			} else {
				const current = pi.getSessionName();
				ctx.ui.notify(current ? `Session: ${current}` : "No session name set", "info");
			}
		},
	});
}
