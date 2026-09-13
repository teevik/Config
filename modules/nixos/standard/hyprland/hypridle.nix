{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.hypridle;
  sectionType = lib.types.attrsOf (
    lib.types.oneOf [
      lib.types.str
      lib.types.int
      lib.types.bool
    ]
  );
  renderSection = name: values: ''
    ${name} {
    ${
      lib.generators.toKeyValue {
        indent = "    ";
        mkKeyValue = lib.generators.mkKeyValueDefault { } " = ";
      } values
    }}
  '';
  configFile = pkgs.writeText "hypridle.conf" (
    lib.concatStringsSep "\n" (
      lib.concatLists (
        lib.mapAttrsToList (name: value: map (renderSection name) (lib.toList value)) cfg.settings
      )
    )
  );
in
{
  options.services.hypridle.settings = lib.mkOption {
    type = lib.types.attrsOf (lib.types.either sectionType (lib.types.listOf sectionType));
    default = { };
    description = ''
      Hypridle configuration. Attribute sets become sections; lists of attribute
      sets become repeated sections, such as listeners, in list order.
      Values may be strings, integers, or booleans.
    '';
    example = {
      listener = [
        {
          timeout = 600;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    # Clear the packaged unit's ExecStart before supplying the generated config.
    systemd.user.services.hypridle.serviceConfig.ExecStart = [
      ""
      "${lib.getExe cfg.package} -c ${configFile}"
    ];
  };
}
