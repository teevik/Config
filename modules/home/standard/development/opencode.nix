{ ... }:
{
  programs.opencode = {
    enable = true;

    settings = {
      theme = "catppuccin";
      permission = {
        edit = "ask";
        bash = "ask";
        webfetch = "ask";
        doom_loop = "ask";
        external_directory = "ask";
      };
    };
  };
}
