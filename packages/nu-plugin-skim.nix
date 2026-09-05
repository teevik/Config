{ pkgs, ... }:
pkgs.nushellPlugins.skim.overrideAttrs (oldAttrs: rec {
  version = "0.30.0";

  src = pkgs.fetchFromGitHub {
    owner = "idanarye";
    repo = "nu_plugin_skim";
    tag = "v${version}";
    hash = "sha256-bZiNUQon4x82XQKINrDYTn6IgEZmLwhhFvmYMTBLOmA=";
  };

  cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
    inherit src;
    hash = "sha256-s0VU8S/V/HJJ5DPLIFvUqhxu9391PJYY/tROUbfJnDQ=";
  };

  nativeInstallCheckInputs = (oldAttrs.nativeInstallCheckInputs or [ ]) ++ [ pkgs.nushell ];
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    plugin_registry="$PWD/skim-plugins.msgpackz"
    nu --plugin-config "$plugin_registry" \
      -c "plugin add $out/bin/nu_plugin_skim"

    runHook postInstallCheck
  '';
})
