import {
  CustomEditor,
  type ExtensionAPI,
  type KeybindingsManager,
} from "@earendil-works/pi-coding-agent";
import type { EditorTheme, TUI } from "@earendil-works/pi-tui";

class HistoryEditor extends CustomEditor {
  constructor(
    tui: TUI,
    theme: EditorTheme,
    private readonly appKeybindings: KeybindingsManager,
  ) {
    super(tui, theme, appKeybindings);
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
