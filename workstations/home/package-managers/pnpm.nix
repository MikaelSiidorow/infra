{
  lib,
  isDarwin ? false,
  packageManagerPolicy,
  ...
}:
let
  inherit (packageManagerPolicy) cooldownMinutes minimumReleaseAgeExcludes;
  minimumReleaseAgeExcludeLines = builtins.concatStringsSep "\n" (
    map (name: "minimum-release-age-exclude[]=${name}") minimumReleaseAgeExcludes
  );
in
{
  home.file = lib.optionalAttrs isDarwin {
    "Library/Preferences/pnpm/rc".text = ''
      minimum-release-age=${toString cooldownMinutes}
      ${minimumReleaseAgeExcludeLines}
    '';
  };

  xdg.configFile = lib.optionalAttrs (!isDarwin) {
    "pnpm/rc".text = ''
      minimum-release-age=${toString cooldownMinutes}
      ${minimumReleaseAgeExcludeLines}
    '';
  };
}
