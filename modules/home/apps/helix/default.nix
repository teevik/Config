{ pkgs, config, lib, inputs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.helix;
  inherit (config.teevik.theme) helixTheme;
in
{
  options.teevik.apps.helix = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable helix
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.teevik.copilot
    ];

    xdg.configFile = {
      "helix/themes/catppuccin_mocha.toml".source = ./themes/catppuccin_mocha.toml;
    };

    # home.file = {
    #   ".envrc".text = ''
    #     export COPILOT_API_KEY=$(cat ${config.age.secrets.copilot.path})
    #     export HANDLER=copilot
    #   '';
    # };

    # home.packages = [
    #   pkgs.teevik.helix-gpt
    # ];

    programs.helix = {
      enable = true;

      package =
        let
          helix = inputs.helix.packages.${pkgs.system}.default;
          helixBin = lib.getExe helix;
          kittyBin = lib.getExe pkgs.kitty;

          helix-kitty-integration = pkgs.writeScriptBin "hx" ''
            #!/usr/bin/env bash
            ${kittyBin} @ set-spacing padding=0
            ${kittyBin} @ set-background-opacity 1

            ${helixBin} -a $1 $2 $3

            ${kittyBin} @ set-spacing padding=10
            ${kittyBin} @ set-background-opacity ${builtins.toJSON config.teevik.apps.kitty.opacity}
          '';
        in
        pkgs.runCommand
          "${helix.name}-kitty-integration"
          { }
          ''
            mkdir -p $out/{share,bin}
            ${pkgs.xorg.lndir}/bin/lndir -silent ${helix}/share $out/share
            cp ${helix-kitty-integration}/bin/hx $out/bin
          ''
      ;

      settings = {
        theme = helixTheme;

        editor = {
          line-number = "relative";
          bufferline = "always";
          color-modes = true;
          # auto-save = true;
          cursorline = true;

          scrolloff = 10;
          completion-trigger-len = 1;
          idle-timeout = 100;

          lsp = {
            display-messages = true;
            display-inlay-hints = true;
          };

          inline-diagnostics = {
            cursor-line = "hint";
            other-lines = "error";
          };

          cursor-shape = {
            insert = "bar";
          };

          indent-guides = {
            render = true;
          };
        };

        keys.normal = {
          "W" = "move_prev_word_start";

          esc = [ "collapse_selection" "keep_primary_selection" ];
          "C-/" = "toggle_comments";

          # ctrl-d from vscode
          # "C-d" = ["move_prev_word_start", move_next_word_end", "search_selection", "extend_search_next"]
          # make sure there is only one selection, select word under cursor, set search to selection, then switch to select mode
          "C-d" = [ "keep_primary_selection" "move_prev_word_start" "move_next_word_end" "search_selection" "select_mode" ];

          space."i" = ":toggle lsp.display-inlay-hints";
        };

        keys.select = {
          "W" = "move_prev_word_start";
          # if already in select mode, just add new selection at next occurrence
          "C-d" = [ "search_selection" "extend_search_next" ];
        };

        keys.insert = {
          "S-tab" = "unindent";
          "C-s" = ":w";
          "C-w" = "copilot_apply_completion";
        };
      };
    };

    xdg.configFile."helix/languages.toml".text = /* toml */ ''
      [[language]]
      name = "prisma"
      auto-format = true

      [language-server.biome]
      command = "biome"
      args = ["lsp-proxy"]

      [language-server.emmet-ls]
      command = "emmet-ls"
      args = ["--stdio"]

      [[language]]
      name = "html"
      language-servers = ["vscode-html-language-server", "emmet-ls"]

      [[language]]
      name = "javascript"
      language-servers = [ { name = "typescript-language-server", except-features = [ "format" ] }, "biome" ]
      auto-format = true

      [[language]]
      name = "typescript"
      language-servers = [ { name = "typescript-language-server", except-features = [ "format" ] }, "biome" ]
      auto-format = true

      [[language]]
      name = "tsx"
      language-servers = [ { name = "typescript-language-server", except-features = [ "format" ] }, "biome", "emmet-ls" ]
      auto-format = true

      [[language]]
      name = "jsx"
      language-servers = [ { name = "typescript-language-server", except-features = [ "format" ] }, "biome", "emmet-ls" ]
      auto-format = true

      [[language]]
      name = "json"
      language-servers = [ { name = "vscode-json-language-server", except-features = [ "format" ] }, "biome" ]
      auto-format = true
    
      [language-server.glsl_analyzer]
      command = "glsl_analyzer"

      [[language]]
      name = "glsl"
      auto-format = true
      file-types = ["glsl", "vert", "frag", "geom", "comp"]
      language-servers = ["glsl_analyzer"]

      [language-server.roc-ls]
      command = "roc_language_server"

      [[language]]
      name = "roc"
      scope = "source.roc"
      injection-regex = "roc"
      file-types = ["roc"]
      shebangs = ["roc"]
      roots = []
      comment-token = "#"
      language-servers = ["roc-ls"]
      indent = { tab-width = 2, unit = "  " }

      [language.auto-pairs]
      '(' = ')'
      '{' = '}'
      '[' = ']'
      '"' = '"'

      [[grammar]]
      name = "roc"
      source = { git = "https://github.com/faldor20/tree-sitter-roc.git", rev = "2c985e01fd1eae1e8ce0d52b084a6b555c26048e" }

      # [language-server.gpt]
      # command = "helix-gpt"

      [language-server.nil]
      config.formatting.command = [ "nixpkgs-fmt" ]

      # [[language]]
      # name = "rust"
      # language-servers = [
      #   "rust-analyzer",
      #   "gpt"
      # ]

      # [language-server.pyright]
      # command = "pyright-langserver"
      # args = ["--stdio"]
      # # will get "Async jobs timed out" errors if this empty config is not added
      # config = {}
      
      [[language]]
      name = "nix"
      auto-format = true

      [[language]]
      name = "cpp"
      auto-format = true
      formatter = { command = "clang-format", args = ["--fallback-style=Google"] }

      # [[language]]
      # name = "python"
      # scope = "source.python"
      # injection-regex = "python"
      # file-types = ["py","pyi","py3","pyw","ptl",".pythonstartup",".pythonrc","SConstruct"]
      # shebangs = ["python"]
      # roots = ["setup.py", "setup.cfg", "pyproject.toml"]
      # comment-token = "#"
      # language-servers = [ "pyright" ]
      # formatter = { command = "black", args = ["-"] }
      # indent = { tab-width = 4, unit = "    " }

      [language-server.pyright]
      command = "pyright-langserver"
      args = ["--stdio"]
      config = { settings = { python = { analysis = { autoImportCompletions = true, typeCheckingMode = "basic", autoSearchPaths = true, useLibraryCodeForTypes = true, diagnosticMode = "openFilesOnly" } } } }

      [language-server.ruff-lsp]
      command = "ruff-lsp"

      [language-server.ruff-lsp.config]
      documentFormatting = true 
      settings.run = "onSave"

      [[language]]
      name = "python"
      scope = "source.python"
      injection-regex = "python"
      auto-format = true
      # formatter = { command = "black", args = ["-", "-q"] }
      file-types = [
        "py",
        "pyi",
        "py3",
        "pyw",
        "ptl",
        ".pythonstartup",
        ".pythonrc",
        "SConstruct",
      ]
      shebangs = ["python"]
      roots = [
        "setup.py",
        "setup.cfg",
        "pyproject.toml",
        "pyrightconfig.json",
        "Poetry.lock",
      ]
      comment-token = "#"
      language-servers = [
        { name = "ruff-lsp", only-features = [ "format", "diagnostics" ] },
        { name = "pyright", except-features = [ "format" ] },
      ]
      indent = { tab-width = 4, unit = "    " }

      [[language]]
      name = "haskell"
      auto-format = true
    '';
  };
}


