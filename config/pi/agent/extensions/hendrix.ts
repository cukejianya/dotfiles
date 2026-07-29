import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const GATEWAY = "https://hendrix-genai.spotify.net/taskforce";

const PROVIDERS = {
  anthropic: {
    baseUrl: `${GATEWAY}/anthropic`,
    api: undefined, // preserve native anthropic-messages format
  },
  openai: {
    baseUrl: `${GATEWAY}/openai/v1`,
    api: undefined, // preserve native openai format
  },
  gemini: {
    baseUrl: `${GATEWAY}/vertexai-gemini/v1`,
    api: "openai-completions" as const,
    models: [
      {
        id: "gemini-2.5-pro",
        name: "Gemini 2.5 Pro",
        reasoning: true,
        input: ["text", "image"] as const,
        cost: { input: 1.25, output: 10.0, cacheRead: 0.31, cacheWrite: 1.56 },
        contextWindow: 1048576,
        maxTokens: 65536,
      },
      {
        id: "gemini-2.5-flash",
        name: "Gemini 2.5 Flash",
        reasoning: true,
        input: ["text", "image"] as const,
        cost: { input: 0.15, output: 0.6, cacheRead: 0.04, cacheWrite: 0.19 },
        contextWindow: 1048576,
        maxTokens: 65536,
      },
      {
        id: "gemini-2.5-flash-lite",
        name: "Gemini 2.5 Flash Lite",
        reasoning: false,
        input: ["text", "image"] as const,
        cost: { input: 0.075, output: 0.3, cacheRead: 0.02, cacheWrite: 0.09 },
        contextWindow: 1048576,
        maxTokens: 65536,
      },
    ],
  },
} as const;

type ProviderName = keyof typeof PROVIDERS;

const AUTH = {
  apiKey: "$TASKFORCE_API_KEY",
  authHeader: true,
  headers: { apikey: "$TASKFORCE_API_KEY" },
};

export default function (pi: ExtensionAPI) {
  const active = new Set<ProviderName>();

  function enable(name: ProviderName) {
    const provider = PROVIDERS[name];
    if (name === "gemini") {
      pi.registerProvider("hendrix-gemini", {
        name: "Gemini (Hendrix)",
        baseUrl: provider.baseUrl,
        api: (provider as typeof PROVIDERS["gemini"]).api,
        models: [...(provider as typeof PROVIDERS["gemini"]).models],
        ...AUTH,
      });
    } else {
      pi.registerProvider(name, {
        baseUrl: provider.baseUrl,
        ...AUTH,
      });
    }
    active.add(name);
  }

  function disable(name: ProviderName) {
    if (name === "gemini") {
      pi.unregisterProvider("hendrix-gemini");
    } else {
      pi.unregisterProvider(name);
    }
    active.delete(name);
  }

  function enableAll() {
    for (const name of Object.keys(PROVIDERS) as ProviderName[]) {
      enable(name);
    }
  }

  function disableAll() {
    for (const name of [...active]) {
      disable(name);
    }
  }

  if (process.env.TASKFORCE_API_KEY) {
    enableAll();
  }

  pi.registerCommand("hendrix", {
    description: "Toggle Hendrix routing [on|off|status] or per-provider [on|off anthropic|openai|gemini]",
    handler: async (args, ctx) => {
      const parts = args.trim().toLowerCase().split(/\s+/);
      const action = parts[0] || "status";
      const target = parts[1] as ProviderName | undefined;

      if (action === "on") {
        if (target && target in PROVIDERS) {
          enable(target);
          ctx.ui.notify(`Hendrix ${target}: ON`, "info");
        } else {
          enableAll();
          ctx.ui.notify("Hendrix: all providers ON", "info");
        }
      } else if (action === "off") {
        if (target && target in PROVIDERS) {
          disable(target);
          ctx.ui.notify(`Hendrix ${target}: OFF`, "info");
        } else {
          disableAll();
          ctx.ui.notify("Hendrix: all providers OFF", "info");
        }
      } else {
        const lines = (Object.keys(PROVIDERS) as ProviderName[])
          .map((p) => `  ${p}: ${active.has(p) ? "ON" : "OFF"}`)
          .join("\n");
        ctx.ui.notify(`Hendrix routing:\n${lines}`, "info");
      }
    },
  });
}
