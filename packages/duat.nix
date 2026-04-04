{ pkgs, ... }:
pkgs.duat.overrideAttrs (
  old:
  let
    oldAttrs = removeAttrs old [ "cargoDeps" ];
  in
  oldAttrs
  // rec {
    version = "0.9.0";
    src = pkgs.fetchFromGitHub {
      owner = "AhoyISki";
      repo = "duat";
      tag = "v${version}";
      hash = "sha256-Wz2WMAgTBTu2qZ8nyuedJJ2UFEwPFkU8jWPYw11R1Wg=";
    };
    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-EtJ0u48uPXsWBBVyRP1jk+1Qmofpd3J/M42Rjrf3zTE=";
    };
  }
)
