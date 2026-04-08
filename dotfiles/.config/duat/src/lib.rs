setup_duat!(setup);
use duat::prelude::*;
use duat::text::TextMut;

// ---------------------------------------------------------------------------
// BufferLine widget
// ---------------------------------------------------------------------------

struct BufferLine {
    text: Text,
}

impl BufferLine {
    fn new() -> Self {
        Self { text: Text::new() }
    }
}

impl Widget for BufferLine {
    fn text(&self) -> &Text {
        &self.text
    }

    fn text_mut(&mut self) -> TextMut<'_> {
        self.text.as_mut()
    }
}

/// Update the BufferLine text based on current buffers
fn update_bufferline(pa: &mut Pass, handle: &Handle<BufferLine>) {
    let current = context::current_buffer(pa);
    let current_name = current.read(pa).name().to_string();
    let buffers = context::buffers(pa);

    let mut builder = Text::builder();

    for (i, buf_handle) in buffers.iter().enumerate() {
        let buf = buf_handle.read(pa);
        let name = buf.name().to_string();
        let filetype = buf.filetype().map(|s: &str| s.to_string());
        let has_changes = buf.text().has_unsaved_changes();
        let _ = buf;

        let is_active = name == current_name;
        let icon = filetype_icon(filetype.as_deref());
        let modified = if has_changes { " ●" } else { "" };
        let entry_text = format!("{icon}{name}{modified}");

        if i > 0 {
            builder.push(txt!("[bufferline.separator] │ "));
        }

        if is_active {
            builder.push(txt!("[bufferline.active]{entry_text}"));
        } else {
            builder.push(txt!("[bufferline.inactive]{entry_text}"));
        }
    }

    handle.write(pa).text = builder.build();
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns a nerd font icon for a given filetype.
fn filetype_icon(filetype: Option<&str>) -> &'static str {
    match filetype {
        Some("rust") => " ",
        Some("python") => " ",
        Some("javascript") => " ",
        Some("typescript") => " ",
        Some("lua") => " ",
        Some("nix") => " ",
        Some("toml") => " ",
        Some("yaml") => " ",
        Some("json") => " ",
        Some("html") => " ",
        Some("css") => " ",
        Some("markdown") => " ",
        Some("go") => " ",
        Some("c") => " ",
        Some("cpp") => " ",
        Some("bash" | "sh" | "zsh") => " ",
        Some("git_commit" | "git_rebase") => " ",
        _ => " ",
    }
}

/// A custom function to show the name differently in the status line.
fn custom_name_txt(buffer: &Buffer, _: &Area) -> Text {
    let mut builder = Text::builder();

    if let Some(name) = buffer.name_set() {
        let icon = filetype_icon(buffer.filetype());
        builder.push(txt!("[buffer]{icon}{name}"));

        if !buffer.exists() {
            builder.push(txt!(" [buffer.new][[new]]"))
        } else if buffer.text().has_unsaved_changes() {
            builder.push(txt!(" [buffer.unsaved]●"))
        }

        builder.build()
    } else {
        txt!("[buffer.new.scratch] {}", buffer.name())
    }
}

// ---------------------------------------------------------------------------
// Setup
// ---------------------------------------------------------------------------

fn setup(opts: &mut Opts) {
    //// Options

    opts.wrap_lines = true;
    opts.indent_wraps = true;
    opts.tabstop = 2;
    opts.scrolloff.y = 5;
    opts.one_line_footer = false;

    // Line numbers
    opts.line_numbers.relative = true;
    opts.line_numbers.align = std::fmt::Alignment::Right;
    opts.line_numbers.main_align = std::fmt::Alignment::Left;

    // WhichKey: always show available bindings in User mode (Space)
    opts.whichkey.always_show::<User>();

    //// Status line with nerd font icons

    opts.fmt_status(|_| {
        let mode = mode_txt();
        let param = duat_param_txt();
        status!(" {mode}  {custom_name_txt}{Spacer}{sels_txt} {param} {main_txt} ")
    });

    //// BufferLine forms (catppuccin mocha palette)

    form::set(
        "bufferline.active",
        Form::new().with("#cba6f7").underlined(),
    );
    form::set("bufferline.inactive", Form::new().with("#a6adc8"));
    form::set("bufferline.separator", Form::new().with("#585b70"));

    //// BufferLine hooks

    // Push a BufferLine to each window (above the buffer area)
    hook::add::<WindowOpened>(|pa, window| {
        let bufferline = BufferLine::new();
        let specs = ui::PushSpecs {
            side: ui::Side::Above,
            height: Some(1.0),
            ..Default::default()
        };
        let handle = window.push_inner(pa, bufferline, specs);

        // Update bufferline when focus changes
        hook::add::<FocusChanged>({
            let handle = handle.clone();
            move |pa, _| update_bufferline(pa, &handle)
        });

        // Initial update
        update_bufferline(pa, &handle);
    });

    //// Remapping

    // Vim-style go to top/bottom
    mode::map::<Normal>("gg", "gk");
    mode::map::<Normal>("G", "gj");
    // Quick escape from insert and prompt
    mode::alias::<Insert>("jk", "<Esc>");
    mode::alias::<Prompt>("jk", "<Esc>");

    //// LSP plugin (semantic tokens only for now)
    plug(duat_lsp::DuatLsp);

    colorscheme::set("catppuccin-mocha");
}
