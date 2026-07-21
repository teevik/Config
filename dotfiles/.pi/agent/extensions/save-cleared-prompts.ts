import {
  CustomEditor,
  type ExtensionAPI,
  type KeybindingsManager,
} from "@earendil-works/pi-coding-agent";
import type { EditorTheme, TUI } from "@earendil-works/pi-tui";

type ExpandedSkillBlock = {
  end: number;
  name: string;
};

const SKILL_OPENING = /^<skill name="([a-z0-9-]+)" location="[^"]*">\r?\n/;

function parseExpandedSkillBlock(
  text: string,
  offset: number,
): ExpandedSkillBlock | undefined {
  const opening = SKILL_OPENING.exec(text.slice(offset));
  const name = opening?.[1];
  if (!opening || !name) return undefined;

  const closingStart = text.indexOf("\n</skill>", offset + opening[0].length);
  if (closingStart === -1) return undefined;

  return {
    name,
    end: closingStart + "\n</skill>".length,
  };
}

function separatorLengthAt(text: string, offset: number): number {
  if (text.startsWith("\r\n\r\n", offset)) return 4;
  if (text.startsWith("\n\n", offset)) return 2;
  return 0;
}

function hasDollarMention(text: string, names: string[]): boolean {
  return names.some((name) => {
    const pattern = new RegExp(`(?:^|[\\t \\n])\\$${name}(?![A-Za-z0-9_-])`);
    return pattern.test(text);
  });
}

/** Reverses Pi's persisted skill expansion for cross-session history. */
export function collapseExpandedSkillPrompt(text: string): string {
  const names: string[] = [];
  let offset = 0;

  while (true) {
    const block = parseExpandedSkillBlock(text, offset);
    if (!block) return text;

    names.push(block.name);
    offset = block.end;

    if (offset === text.length) break;

    const separatorLength = separatorLengthAt(text, offset);
    if (separatorLength === 0) return text;

    const nextOffset = offset + separatorLength;
    if (parseExpandedSkillBlock(text, nextOffset)) {
      offset = nextOffset;
      continue;
    }

    offset = nextOffset;
    break;
  }

  const remainder = text.slice(offset);
  if (remainder && hasDollarMention(remainder, names)) return remainder;

  const firstName = names[0];
  if (!firstName) return text;
  return `/skill:${firstName}${remainder ? ` ${remainder}` : ""}`;
}

class HistoryEditor extends CustomEditor {
  private readonly appKeybindings: KeybindingsManager;

  constructor(
    tui: TUI,
    theme: EditorTheme,
    appKeybindings: KeybindingsManager,
  ) {
    super(tui, theme, appKeybindings);
    this.appKeybindings = appKeybindings;
  }

  override addToHistory(text: string): void {
    super.addToHistory(collapseExpandedSkillPrompt(text));
  }

  override handleInput(data: string): void {
    if (this.appKeybindings.matches(data, "app.clear")) {
      const prompt = this.getExpandedText();
      if (prompt.trim()) this.addToHistory(prompt);
    }

    super.handleInput(data);
  }
}

export default function saveClearedPrompts(pi: ExtensionAPI): void {
  pi.on("session_start", (_event, ctx) => {
    if (ctx.mode !== "tui") return;

    ctx.ui.setEditorComponent(
      (tui, theme, keybindings) => new HistoryEditor(tui, theme, keybindings),
    );
  });
}
