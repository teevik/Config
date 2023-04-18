{ lib,  ... }:
{
  options.pagman.user = with lib.types; {
    extraGroups = mkOpt (listOf str) [ ] "Groups for the user to be assigned.";
  };

  config = {
  };
}