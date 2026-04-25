# Package manager policy shared across tool-specific modules.
{
  ...
}:
let
  cooldownDays = 7;
in
{
  imports = [
    ./bun.nix
    ./pnpm.nix
    ./uv.nix
  ];

  _module.args.packageManagerPolicy = {
    inherit cooldownDays;
    cooldownMinutes = cooldownDays * 24 * 60;
    cooldownSeconds = cooldownDays * 24 * 60 * 60;
    cooldownDuration = "${toString cooldownDays} days";
  };
}
