# Claude Code: cross-machine config files
#
# Only the files I author live here. settings.json is intentionally left
# machine-local because Claude Code appends permission entries to it at
# runtime; symlinking it read-only would break that flow.
{ ... }:
{
  home.file = {
    ".claude/CLAUDE.md".source = ./claude-code/CLAUDE.md;
    ".claude/statusline-command.sh" = {
      source = ./claude-code/statusline-command.sh;
      # Claude Code runs the statusLine command through a shell, so the file
      # must be executable; nix store copies are read-only without this.
      executable = true;
    };
  };
}
