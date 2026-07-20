export interface ResolvedReference {
  alias: string;
  kind: "local" | "git";
  dir: string;
  description?: string;
  hidden: boolean;
  state: "ready" | "pending" | "error";
}

export function buildReferencesPrompt(references: ResolvedReference[]): string | undefined {
  const advertised = references.filter((ref) => ref.description !== undefined);
  if (advertised.length === 0) return undefined;

  const lines = advertised.map((ref) => {
    const suffix = ref.state === "pending" ? " (repository is still being cloned)" : "";
    return `- ${ref.alias}: ${ref.dir} — ${ref.description}${suffix}`;
  });

  return [
    "## Reference directories",
    "",
    "External reference directories configured for this project. Treat them as read-only reference material — do not edit files inside them. When a task matches a description below, read files from that directory instead of guessing.",
    "",
    ...lines,
  ].join("\n");
}
