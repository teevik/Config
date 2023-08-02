{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.vscode;
  # extensionFromVscodeMarketplace = pkgs.vscode-utils.extensionFromVscodeMarketplace;
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
    teevik.home = {
      programs.vscode = {
        enable = true;

        userSettings = {
          "workbench.colorTheme" = "Everforest Dark"; # changeable
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

        # extensions = with pkgs.vscode-extensions;[
        #   cargo-crate-completer
        # ];
      };
    };
  };
}
