{ inputs, ... }:
{
  config = {
    services.openssh = {
      enable = true;
    };
  };
}