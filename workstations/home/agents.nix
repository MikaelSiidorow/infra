# Agent config: cross-machine authored files.
#
# Keep mutable runtime files (auth, caches, local settings, histories) out of
# Nix. This module only links files we intentionally author in this repo.
{ lib, ... }:
let
  skillTargets = {
    codex = name: ".codex/skills/${name}";
    claude-code = name: ".claude/skills/${name}";
  };

  skills = {
    ponytail = {
      source = ./agents/skills/ponytail;
      agents = [
        "codex"
        "claude-code"
      ];
    };
  };

  mkSkillFiles =
    name: skill:
    lib.listToAttrs (
      map (agent: {
        name = skillTargets.${agent} name;
        value = {
          inherit (skill) source;
        };
      }) skill.agents
    );

  skillFiles = lib.foldl' (acc: fileSet: acc // fileSet) { } (lib.mapAttrsToList mkSkillFiles skills);
in
{
  home.file = skillFiles // {
    ".claude/CLAUDE.md".source = ./agents/shared/AGENTS.md;
    ".claude/statusline-command.sh" = {
      source = ./agents/claude-code/statusline-command.sh;
      # Claude Code runs the statusLine command through a shell, so the file
      # must be executable; nix store copies are read-only without this.
      executable = true;
    };
  };
}
