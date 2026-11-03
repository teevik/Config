{ inputs, ... }:
{
  imports = [ inputs.hyprsession.nixosModules.default ];

  programs.hyprsession = {
    enable = true;
    # T3 Code's desktop file is t3code.desktop, but its window class is
    # com.t3tools.T3Code, so hyprsession can't find the launcher by itself.
    settings.commands."com.t3tools.T3Code" = "t3code-desktop";
  };
}
