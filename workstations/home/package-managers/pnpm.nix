{
  lib,
  isDarwin ? false,
  packageManagerPolicy,
  ...
}:
let
  inherit (packageManagerPolicy) cooldownMinutes;
in
{
  home.file = lib.optionalAttrs isDarwin {
    "Library/Preferences/pnpm/rc".text = ''
      minimum-release-age=${toString cooldownMinutes}
    '';
  };

  xdg.configFile = lib.optionalAttrs (!isDarwin) {
    "pnpm/rc".text = ''
      minimum-release-age=${toString cooldownMinutes}
    '';
  };
}
