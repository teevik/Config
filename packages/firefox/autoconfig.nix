{
  pkgs,
}:

# Firefox wrapper args that apply prefs and userContent.css through autoconfig,
# so the config works in whatever profile Firefox picks and profiles.ini can
# stay machine-local.
let
  inherit (pkgs) lib;
  prefs = import ./prefs.nix;

  # Prefs that were once in prefs.nix and may still linger as user values
  legacyUserPrefs = [
    "browser.sessionhistory.max_total_viewers"
    "dom.security.https_only_mode"
    "dom.security.https_only_mode_error_page_user_suggestions"
    "network.dnsCacheExpiration"
    "network.http.max-connections"
    "network.http.max-persistent-connections-per-server"
    "network.http.pacing.requests.enabled"
    "network.http.request.max-start-delay"
  ];

  autoconfig = pkgs.writeText "firefox-prefs.js" ''
    // One-time migration: these prefs used to be applied with pref(), which left
    // user values in prefs.js that would now shadow the defaults set below.
    try {
      if (!getPref("autoconfig.migratedToDefaultPrefs")) {
        ${lib.concatMapStringsSep "\n        " (name: "clearPref(${builtins.toJSON name});") (
          lib.attrNames prefs ++ legacyUserPrefs
        )}
        pref("autoconfig.migratedToDefaultPrefs", true);
      }
    } catch (e) {
      Components.utils.reportError(e);
    }
    ${lib.concatLines (
      lib.mapAttrsToList (
        name: value: "defaultPref(${builtins.toJSON name}, ${builtins.toJSON value});"
      ) prefs
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
