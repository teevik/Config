{ inputs, pkgs, config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.vscode;
  extensions = inputs.nix-vscode-extensions.extensions.${pkgs.system}.vscode-marketplace;
in
{
  options.teevik.apps.vscode = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable vscode
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.vscode = {
      enable = true;

      userSettings = {
        "workbench.colorTheme" = config.teevik.theme.vscodeTheme;
        "editor.tabSize" = 2;
        "git.autofetch" = true;
        "editor.fontFamily" = "JetBrains Mono, Consolas, 'Courier New', monospace";
        "editor.fontSize" = 13;
        "editor.inlayHints.padding" = true;
        "editor.lineHeight" = 1.7;

        "typescript.inlayHints.enumMemberValues.enabled" = true;
        "typescript.inlayHints.functionLikeReturnTypes.enabled" = true;
        "typescript.inlayHints.parameterNames.enabled" = "literals";
        "typescript.inlayHints.parameterTypes.enabled" = true;
        "typescript.inlayHints.propertyDeclarationTypes.enabled" = true;

        "security.workspace.trust.untrustedFiles" = "open";

        "window.titleBarStyle" = "custom";
        "editor.formatOnSave" = true;

        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
        "nix.serverSettings" = {
          "nil" = {
            "formatting" = { "command" = [ "nixpkgs-fmt" ]; };
          };
        };

        "editor.defaultFormatter" = "esbenp.prettier-vscode";

        "[nix]" = {
          "editor.defaultFormatter" = "jnoortheen.nix-ide";
        };
      };

      extensions = with extensions; [
        # Typescript/javascript
        ms-vscode.vscode-typescript-next
        paulmolluzzo.convert-css-in-js
        sanity-io.vscode-sanity
        styled-components.vscode-styled-components

        # Nix
        jnoortheen.nix-ide

        # Rust
        chenxuan.cargo-crate-completer
        rust-lang.rust-analyzer
        tamasfe.even-better-toml
        serayuzgur.crates

        # c/c++
        jeff-hykin.better-cpp-syntax
        ms-vscode.cpptools-extension-pack

        # Python
        ms-python.python
        ms-python.vscode-pylance


        # Haskell
        haskell.haskell

        # Highlighting
        naumovs.color-highlight

        # Tools
        eamodio.gitlens
        ms-vscode.hexeditor
        ms-toolsai.jupyter
        skellock.just
        christian-kohler.path-intellisense
        esbenp.prettier-vscode
        pdconsec.vscode-print

        # Remote
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-ssh-edit
        ms-vscode.remote-explorer


        # Themes
        catppuccin.catppuccin-vsc
        sainnhe.everforest


        # (extensionFromVscodeMarketplace {
        #   name = "cargo-crate-completer";
        #   publisher = "chenxuan";
        #   version = "1.0.2";
        #   sha256 = "sha256-Kfx1GgPJiTSLYZOSe5R8g1EiyHdptwdog2D221zjQIg=";
        # })
      ];
    };
  };
}