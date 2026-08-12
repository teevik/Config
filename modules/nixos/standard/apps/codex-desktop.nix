{
  inputs,
  perSystem,
  ...
}:
{
  imports = [ inputs.codex-desktop-linux.nixosModules.default ];

  programs.codexDesktopLinux = {
    enable = true;
    cliPackage = perSystem.llm-agents.codex;
    computerUseUi.enable = true;
    linuxFeatures = [ "open-target-discovery" ];
  };
}
