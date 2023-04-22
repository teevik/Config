{ pkgs, ... }: 
{
  config = {
    environment.systemPackages = with pkgs; [
      libnotify
    ];
  };

  config.home = {
    services.mako = {
      enable = true;
    };
  };
}