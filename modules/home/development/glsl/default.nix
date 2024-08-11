{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.development.glsl;
in
{
  options.teevik.development.glsl = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable glsl
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      glsl_analyzer
      renderdoc
      (writeScriptBin "ngfx-ui-wrapper" ''
        ngfx_ui=''${1?}
        directory=$(dirname "''$ngfx_ui")
        export LD_LIBRARY_PATH="''$LD_LIBRARY_PATH":"''$directory":${
          lib.makeLibraryPath [
            krb5 # libgssapi_krb5.so.2
            xcb-util-cursor # libxcb-cursor.so.0
            xorg.xcbutilimage # libxcb-image.so.0
            xorg.xcbutilkeysyms # libxcb-keysyms.so.1
            xorg.xcbutilrenderutil # libxcb-render-util.so.0
            xorg.xcbutilwm # libxcb-icccm.so.4
          ]
        }
        # Could not find the Qt platform plugin "wayland" in ""
        # Could not find the Qt platform plugin "xcb" in ""
        #  - Qt plugin search path: .../opt/nvidia/nsight-graphics-for-linux/nsight-graphics-for-linux-2024.1.0.0/host/linux-desktop-nomad-x64
        export QT_PLUGIN_PATH="''$directory"/Plugins
        "${steam-run}"/bin/steam-run "''$@"
      '')
      # (pkgs.symlinkJoin {
      #   name = "hello";
      #   paths = [ pkgs.renderdoc ];
      #   buildInputs = [ pkgs.makeWrapper ];
      #   postBuild = ''
      #     wrapProgram $out/bin/qrenderdoc \
      #       --set WAYLAND_DISPLAY "-t"
      #   '';
      # })
    ];
  };
}
