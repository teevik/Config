{ pkgs, ... }: {
  programs.adb.enable = true;
  users.users.teevik.extraGroups = [ "kvm" "adbusers" ];

  environment.systemPackages = [ pkgs.android-studio ];
}
