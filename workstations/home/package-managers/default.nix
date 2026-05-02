# Package manager policy shared across tool-specific modules.
{
  ...
}:
let
  cooldownDays = 7;
  minimumReleaseAgeExcludes = [
    "create-mikstack"
    "@mikstack/*"
    "@openai/codex"
  ];
in
{
  imports = [
    ./bun.nix
    ./pnpm.nix
    ./uv.nix
  ];

  _module.args.packageManagerPolicy = {
    inherit cooldownDays;
    inherit minimumReleaseAgeExcludes;
    cooldownMinutes = cooldownDays * 24 * 60;
    cooldownSeconds = cooldownDays * 24 * 60 * 60;
    cooldownDuration = "${toString cooldownDays} days";
  };
}
