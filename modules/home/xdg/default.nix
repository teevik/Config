{ pkgs, config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.xdg;

  browser = [ "firefox" ];
  imageViewer = [ "org.gnome.Loupe" ];
  videoPlayer = [ "mpv" ];
  audioPlayer = [ "mpv" ];
  compressionHandler = [ "org.gnome.Nautilus" ];

  xdgAssociations = type: program: list:
    builtins.listToAttrs (map
      (e: {
        name = "${type}/${e}";
        value = program;
      })
      list);

  image = xdgAssociations "image" imageViewer [ "png" "svg" "jpeg" "gif" ];
  video = xdgAssociations "video" videoPlayer [ "mp4" "avi" "mkv" ];
  audio = xdgAssociations "audio" audioPlayer [ "mp3" "flac" "wav" "aac" ];
  compression = xdgAssociations "compression" compressionHandler [
    "application/bzip2"
    "application/gzip"
    "application/vnd.rar"
    "application/x-7z-compressed"
    "application/x-7z-compressed-tar"
    "application/x-bzip"
    "application/x-bzip-compressed-tar"
    "application/x-compress"
    "application/x-compressed-tar"
    "application/x-cpio"
    "application/x-gzip"
    "application/x-lha"
    "application/x-lzip"
    "application/x-lzip-compressed-tar"
    "application/x-lzma"
    "application/x-lzma-compressed-tar"
    "application/x-tar"
    "application/x-tarz"
    "application/x-xar"
    "application/x-xz"
    "application/x-xz-compressed-tar"
    "application/zip"
  ];


  browserTypes =
    (xdgAssociations "application" browser [
      "json"
      "x-extension-htm"
      "x-extension-html"
      "x-extension-shtml"
      "x-extension-xht"
      "x-extension-xhtml"
    ])
    // (xdgAssociations "x-scheme-handler" browser [
      "about"
      "ftp"
      "http"
      "https"
      "unknown"
    ]);

  associations = builtins.mapAttrs (_: v: (map (e: "${e}.desktop") v)) ({
    "application/pdf" = [ "com.github.xournalpp.xournalpp" ];
    "text/html" = browser;
    "text/plain" = [ "Helix" ];
    "inode/directory" = [ "org.gnome.Nautilus" ];
  }
  // image
  // video
  // audio
  // compression
  // browserTypes);
in
{
  options.teevik.xdg = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable xdg
      '';
    };
  };

  config = mkIf cfg.enable {
    xdg = {
      enable = true;

      mimeApps = {
        enable = true;
        defaultApplications = associations;
      };

      userDirs = {
        enable = true;
        createDirectories = true;

        extraConfig = {
          XDG_SCREENSHOTS_DIR = "${config.home.homeDirectory}/Pictures/Screenshots";
        };
      };
    };

    home.packages = [
      # used by `gio open` and xdp-gtk
      (pkgs.writeShellScriptBin "xdg-terminal-exec" ''
        kitty "$@"
      '')
      pkgs.xdg-utils
    ];
  };
}
