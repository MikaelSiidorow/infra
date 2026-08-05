{
  pkgs-unstable,
  lib,
  username,
  ...
}:
let
  llm = import ../../lib/llm.nix { inherit pkgs-unstable lib; };
in
{
  users = {
    knownUsers = [ llm.serviceUser ];
    knownGroups = [ llm.serviceUser ];
    groups.${llm.serviceUser} = {
      gid = llm.serviceUid;
      members = [ username ];
    };
    users.${llm.serviceUser} = {
      uid = llm.serviceUid;
      gid = llm.serviceUid;
      # A cache-backed home makes macOS create SIP-protected directories in it.
      home = "/var/empty";
      shell = "/usr/bin/false";
      description = "Local LLM inference service";
    };
  };

  system.activationScripts.postActivation.text = ''
    # setgid keeps user-downloaded weights readable by the service account.
    for d in ${llm.cacheDir} ${llm.cacheDir}/hf ${llm.logDir} ${llm.homeDir}; do
      /usr/bin/install -d -o ${toString llm.serviceUid} -g ${toString llm.serviceUid} -m 2770 "$d"
    done
  '';

  launchd.daemons.llama-swap.serviceConfig = {
    ProgramArguments = [
      "${pkgs-unstable.llama-swap}/bin/llama-swap"
      "-config"
      "${llm.swapConfig}"
      "-listen"
      "127.0.0.1:${toString llm.port}"
    ];
    UserName = llm.serviceUser;
    GroupName = llm.serviceUser;
    RunAtLoad = true;
    KeepAlive = true;
    EnvironmentVariables = {
      HF_HOME = "${llm.cacheDir}/hf";
      # Only llm-pull may access the network or mutate the shared cache.
      HF_HUB_OFFLINE = "1";
      HOME = llm.homeDir;
    };
    StandardOutPath = "${llm.logDir}/llama-swap.log";
    StandardErrorPath = "${llm.logDir}/llama-swap.log";
  };
}
