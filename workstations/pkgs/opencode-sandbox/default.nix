{
  writeShellApplication,
  git,
  python3,
  nix,
}:
let
  runner = writeShellApplication {
    name = "opencode-sandbox-run";
    text = ''
      : "''${OPENCODE_SANDBOX_HOME:?}"
      : "''${OPENCODE_SANDBOX_USER_PROFILE:?}"

      workspace=$(${git}/bin/git rev-parse --show-toplevel) || {
        echo "opencode: run inside a Git worktree so ignored files can be sandboxed" >&2
        exit 1
      }
      workspace=$(cd "$workspace" && pwd -P)
      sandboxTmp=$(mktemp -d "''${TMPDIR:-/tmp}/opencode-sandbox.XXXXXX")
      sandboxTmp=$(cd "$sandboxTmp" && pwd -P)
      runtimeProfile="$sandboxTmp/opencode.sb"
      trap 'rm -rf -- "$sandboxTmp"' EXIT

      opencodeData="$OPENCODE_SANDBOX_HOME/.local/share/opencode"
      opencodeState="$OPENCODE_SANDBOX_HOME/.local/state/opencode"
      opencodeCache="$OPENCODE_SANDBOX_HOME/.cache/opencode"
      mkdir -p "$opencodeData" "$opencodeState" "$opencodeCache"

      cp '${./opencode.sb.in}' "$runtimeProfile"
      chmod 600 "$runtimeProfile"
      ${python3}/bin/python3 '${./ignored-rules.py}' '${git}/bin/git' "$workspace" >> "$runtimeProfile"

      export TMPDIR="$sandboxTmp"
      /usr/bin/sandbox-exec \
        -D "WORKSPACE=$workspace" \
        -D "TMPDIR=$sandboxTmp" \
        -D "USER_PROFILE=$OPENCODE_SANDBOX_USER_PROFILE" \
        -D "OPENCODE_CONFIG=$OPENCODE_SANDBOX_HOME/.config/opencode" \
        -D "GIT_CONFIG_DIR=$OPENCODE_SANDBOX_HOME/.config/git" \
        -D "CLAUDE_SKILLS=$OPENCODE_SANDBOX_HOME/.claude/skills" \
        -D "OPENCODE_DATA=$opencodeData" \
        -D "OPENCODE_STATE=$opencodeState" \
        -D "OPENCODE_CACHE=$opencodeCache" \
        -D "BUN_HOME=$OPENCODE_SANDBOX_HOME/.bun" \
        -D "PNPM_HOME=$OPENCODE_SANDBOX_HOME/.local/share/pnpm" \
        -D "LOCAL_BIN=$OPENCODE_SANDBOX_HOME/.local/bin" \
        -D "ORBSTACK_BIN=$OPENCODE_SANDBOX_HOME/.orbstack/bin" \
        -D "FNM_STATE=$OPENCODE_SANDBOX_HOME/.local/state/fnm_multishells" \
        -D "ZSHENV=$OPENCODE_SANDBOX_HOME/.zshenv" \
        -D "ZPROFILE=$OPENCODE_SANDBOX_HOME/.zprofile" \
        -D "ZSHRC=$OPENCODE_SANDBOX_HOME/.zshrc" \
        -D "GIT_CONFIG=$OPENCODE_SANDBOX_HOME/.gitconfig" \
        -f "$runtimeProfile" \
        "$@"
    '';
  };

  test = writeShellApplication {
    name = "opencode-sandbox-test";
    runtimeInputs = [
      git
      nix
    ];
    excludeShellChecks = [ "SC2016" ];
    text = ''
      testTmp=$(mktemp -d "''${TMPDIR:-/tmp}/opencode-sandbox-test.XXXXXX")
      trap 'rm -rf -- "$testTmp"' EXIT

      fixture="$testTmp/repo"
      home="$testTmp/home"
      outside="$testTmp/outside"
      mkdir -p "$fixture/ignored" "$home" "$outside"
      printf '.env\nignored/\n' > "$fixture/.gitignore"
      printf 'tracked\n' > "$fixture/tracked.txt"
      printf 'secret\n' > "$fixture/.env"
      printf 'secret\n' > "$fixture/ignored/secret.txt"
      git -C "$fixture" init -q
      git -C "$fixture" add .gitignore tracked.txt

      export OPENCODE_SANDBOX_HOME="$home"
      export OPENCODE_SANDBOX_USER_PROFILE="$home"
      cd "$fixture"
      ${runner}/bin/opencode-sandbox-run /bin/sh -eu -c '
        fixture=$1
        outside=$2

        cat "$fixture/tracked.txt" >/dev/null
        touch "$fixture/created.txt"
        mkdir "$TMPDIR/opencode"
        git -C "$fixture" status --short >/dev/null
        nix --version >/dev/null

        ! cat "$fixture/.env" >/dev/null 2>&1
        ! cat "$fixture/ignored/secret.txt" >/dev/null 2>&1
        ! touch "$outside/escaped" 2>/dev/null
        ! cat /private/etc/hosts >/dev/null 2>&1
      ' sh "$fixture" "$outside"
    '';
  };

  wrap =
    {
      opencode,
      homeDirectory,
      username,
    }:
    writeShellApplication {
      name = "opencode";
      text = ''
        : '${test}'
        export OPENCODE_SANDBOX_HOME='${homeDirectory}'
        export OPENCODE_SANDBOX_USER_PROFILE='/etc/profiles/per-user/${username}'
        exec '${runner}/bin/opencode-sandbox-run' '${opencode}/bin/opencode' "$@"
      '';
    };
in
{
  inherit runner test wrap;
}
