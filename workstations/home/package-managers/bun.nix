{
  packageManagerPolicy,
  ...
}:
let
  inherit (packageManagerPolicy) cooldownSeconds minimumReleaseAgeExcludes;
in
{
  home.file.".bunfig.toml".text = ''
    [install]
    minimumReleaseAge = ${toString cooldownSeconds}
    minimumReleaseAgeExcludes = [${
      builtins.concatStringsSep ", " (map (name: "\"${name}\"") minimumReleaseAgeExcludes)
    }]
  '';
}
