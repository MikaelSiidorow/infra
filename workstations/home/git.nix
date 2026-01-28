# Git configuration - platform-agnostic
{ pkgs, ... }:
{
  home.file.".config/git/attributes" = {
    text = ''
      * merge=mergiraf
    '';
  };

  programs.git = {
    enable = true;
    ignores = [
      ".DS_STORE"
      "CLAUDE.md"
      ".claude"
      ".github/copilot-instructions.md"
      "todo.md"
    ];
    userName = "Mikael Siidorow";
    userEmail = "mikael.siidorow@teamspective.com";
    extraConfig = {
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
