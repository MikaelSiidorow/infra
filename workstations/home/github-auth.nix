# GitHub API auth: raises the 60 req/hr unauthenticated cap to 5000. A
# read-only / no-scope PAT in sops (github.token) suffices.
{ config, ... }:
{
  sops.secrets."github/token" = {
    mode = "0600";
  };

  # uv only. Setting GITHUB_TOKEN/GH_TOKEN would shadow gh's keyring login,
  # which holds the real scopes.
  programs.zsh.envExtra = ''
    if [[ -r "${config.sops.secrets."github/token".path}" ]]; then
      export UV_GITHUB_TOKEN="$(< "${config.sops.secrets."github/token".path}")"
    fi
  '';
}
