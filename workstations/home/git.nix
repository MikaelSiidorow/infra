# Git configuration - platform-agnostic
{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    attributes = [ "* merge=mergiraf" ];
    ignores = [
      ".DS_STORE"
      "CLAUDE.md"
      ".claude"
      ".github/copilot-instructions.md"
      "todo.md"
    ];
    settings = {
      user = {
        name = "Mikael Siidorow";
        email = "mikael.siidorow@teamspective.com";
      };
      init.defaultBranch = "main";
      core = {
        autocrlf = "input";
      };
      branch.sort = "-committerdate";
      merge.conflictstyle = "zdiff3";
      pull.ff = "only";
      rebase.autoStash = true;
      rerere.enabled = true;

      "merge \"mergiraf\"" = {
        name = "mergiraf";
        driver = "${pkgs.mergiraf}/bin/mergiraf merge --git %O %A %B -s %S -x %X -y %Y -p %P -l %L";
      };
    };
  };
}
