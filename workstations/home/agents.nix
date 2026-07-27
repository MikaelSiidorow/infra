# Agent config: cross-machine authored files.
#
# Keep mutable runtime files (auth, caches, local settings, histories) out of
# Nix. This module only links files we intentionally author in this repo.
{
  lib,
  isDarwin ? false,
  ...
}:
let
  skillTargets = {
    codex = name: ".codex/skills/${name}";
    claude-code = name: ".claude/skills/${name}";
    opencode = name: ".config/opencode/skills/${name}";
  };

  # codex and opencode CLIs are Linux-only (see packages.nix). Skip their skill
  # copies on darwin; otherwise cursor-agent, which scans both ~/.claude and
  # ~/.codex, lists every skill twice. cursor-agent needs no target of its own
  # since it reads ~/.claude/skills.
  unavailableAgents = lib.optionals isDarwin [
    "codex"
    "opencode"
  ];

  skillTargetPaths =
    name: agents:
    let
      availableAgents = builtins.filter (agent: !(builtins.elem agent unavailableAgents)) agents;
      # OpenCode also reads ~/.claude/skills. If a skill targets both tools,
      # install it once there so OpenCode does not see duplicate skill names.
      effectiveAgents =
        if builtins.elem "claude-code" availableAgents && builtins.elem "opencode" availableAgents then
          builtins.filter (agent: agent != "opencode") availableAgents
        else
          availableAgents;
    in
    lib.unique (map (agent: skillTargets.${agent} name) effectiveAgents);

  skills = {
    humanizer = {
      source = ./agents/skills/humanizer;
      agents = [
        "codex"
        "claude-code"
      ];
    };

    ponytail = {
      source = ./agents/skills/ponytail;
      agents = [
        "codex"
        "claude-code"
        "opencode"
      ];
    };

    # cursor-agent reads ~/.claude/skills, so the claude-code target covers it.
    cursor-agent = {
      source = ./agents/skills/cursor-agent;
      agents = [ "claude-code" ];
    };
  };

  mkSkillFiles =
    name: skill:
    lib.listToAttrs (
      map (path: {
        name = path;
        value = {
          inherit (skill) source;
        };
      }) (skillTargetPaths name skill.agents)
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
