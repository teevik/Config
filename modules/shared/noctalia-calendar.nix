{ config, lib, ... }:
{
  sops.secrets.school-calendar-url = {
    owner = lib.mkDefault "teevik";
    mode = "0400";
  };

  # Substitute the URL at activation, keeping plaintext out of the Nix store.
  # The shared Noctalia config includes this same path on every graphical host.
  sops.templates."noctalia-school-calendar.toml" = {
    owner = config.sops.secrets.school-calendar-url.owner;
    # Precision's user is managed by the host OS, not a Nix users.users entry.
    group = "root";
    mode = "0400";
    path = "/run/secrets-rendered/noctalia-school-calendar.toml";
    content = ''
      [calendar]
      enabled = true
      refresh_minutes = 15

      [calendar.account.school]
      type = "ics"
      name = "School"
      server_url = "${config.sops.placeholder.school-calendar-url}"
    '';
  };
}
