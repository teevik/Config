{
  pkgs,
}:

# Firefox wrapper args that apply prefs and userContent.css through autoconfig,
# so the config works in whatever profile Firefox picks and profiles.ini can
# stay machine-local.
let
  inherit (pkgs) lib;
  prefs = import ./prefs.nix;

  autoconfig = pkgs.writeText "firefox-prefs.js" ''
    ${lib.concatLines (
      lib.mapAttrsToList (name: value: "pref(${builtins.toJSON name}, ${builtins.toJSON value});") prefs
    )}
    // Register userContent.css as a user sheet, like a profile's chrome/userContent.css
    try {
      const Cc = Components.classes;
      const Ci = Components.interfaces;
      const sss = Cc["@mozilla.org/content/style-sheet-service;1"].getService(Ci.nsIStyleSheetService);
      const io = Cc["@mozilla.org/network/io-service;1"].getService(Ci.nsIIOService);
      const uri = io.newURI("file://${./userContent.css}");
      if (!sss.sheetRegistered(uri, sss.USER_SHEET)) {
        sss.loadAndRegisterSheet(uri, sss.USER_SHEET);
      }
    } catch (e) {
      Components.utils.reportError(e);
    }
  '';
in
{
  extraPrefsFiles = [ autoconfig ];
  # The stylesheet service needs XPCOM access, which the autoconfig sandbox blocks
  extraAutoConfig = ''
    pref("general.config.sandbox_enabled", false);
  '';
}
