{ config, pkgs, lib, ... }:

let
  kubectl = "${pkgs.kubectl}/bin/kubectl";

  # Define deploy projects — add new entries here to onboard more repos
  projects = {
    refinery = {
      namespace = "refinery";
      deployments = [ "refinery-app" "refinery-zero" ];
      sshPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB2kXgFEFtNxTm8WXQfPH6iqZtjU+bN6bLzgJaPUB6BT refinery-deploy";
    };
  };

  # Generate a wrapper script per project that restricts kubectl usage
  mkWrapperScript = name: project:
    pkgs.writeShellScript "deploy-${name}" ''
      set -euo pipefail
      export KUBECONFIG="/etc/k8s/deploy-${name}.kubeconfig"

      # Only allow the command provided via SSH_ORIGINAL_COMMAND
      cmd="''${SSH_ORIGINAL_COMMAND:-}"
      if [ -z "$cmd" ]; then
        echo "Interactive sessions not allowed" >&2
        exit 1
      fi

      # Only allow kubectl commands
      case "$cmd" in
        kubectl\ *)
          read -ra args <<< "''${cmd#kubectl }"
          case "''${args[0]}" in
            get|patch|rollout|apply|diff)
              exec ${kubectl} "''${args[@]}"
              ;;
            *)
              echo "Subcommand '''''${args[0]}' not allowed" >&2
              exit 1
              ;;
          esac
          ;;
        *)
          echo "Only kubectl commands are allowed" >&2
          exit 1
          ;;
      esac
    '';

  # Generate authorized_keys entries with command= restriction
  mkAuthorizedKey = name: project:
    let wrapper = mkWrapperScript name project;
    in ''command="${wrapper}",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ${project.sshPubKey}'';

  # Generate the kubeconfig setup script for all projects
  setupScript = pkgs.writeShellScript "generate-deploy-kubeconfigs" ''
    set -euo pipefail
    export KUBECONFIG="/etc/rancher/k3s/k3s.yaml"

    mkdir -p /etc/k8s

    ${lib.concatStringsSep "\n" (lib.mapAttrsToList mkProjectSetup projects)}
  '';

  mkProjectSetup = name: project: ''
    echo "Setting up deploy credentials for ${name}..."

    # Create ServiceAccount
    ${kubectl} apply -f - <<'YAML'
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: ${name}-deployer
      namespace: ${project.namespace}
    YAML

    # Create Role — only get/list/patch deployments
    ${kubectl} apply -f - <<'YAML'
    apiVersion: rbac.authorization.k8s.io/v1
    kind: Role
    metadata:
      name: ${name}-deployer
      namespace: ${project.namespace}
    rules:
      - apiGroups: ["apps"]
        resources: ["deployments"]
        verbs: ["get", "list", "patch"]
    YAML

    # Create RoleBinding
    ${kubectl} apply -f - <<'YAML'
    apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: ${name}-deployer
      namespace: ${project.namespace}
    subjects:
      - kind: ServiceAccount
        name: ${name}-deployer
        namespace: ${project.namespace}
    roleRef:
      kind: Role
      name: ${name}-deployer
      apiGroup: rbac.authorization.k8s.io
    YAML

    # Create long-lived SA token Secret
    ${kubectl} apply -f - <<YAML
    apiVersion: v1
    kind: Secret
    metadata:
      name: ${name}-deployer-token
      namespace: ${project.namespace}
      annotations:
        kubernetes.io/service-account.name: ${name}-deployer
    type: kubernetes.io/service-account-token
    YAML

    # Wait for token to be populated
    for i in $(seq 1 30); do
      token=$(${kubectl} get secret ${name}-deployer-token -n ${project.namespace} -o jsonpath='{.data.token}' 2>/dev/null || true)
      if [ -n "$token" ]; then
        break
      fi
      sleep 1
    done

    token=$(${kubectl} get secret ${name}-deployer-token -n ${project.namespace} -o jsonpath='{.data.token}' | base64 -d)
    server=$(${kubectl} config view --minify -o jsonpath='{.clusters[0].cluster.server}')
    ca=$(${kubectl} config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')

    # Generate project-scoped kubeconfig
    cat > /etc/k8s/deploy-${name}.kubeconfig <<KUBECONFIG
    apiVersion: v1
    kind: Config
    clusters:
      - name: default
        cluster:
          server: $server
          certificate-authority-data: $ca
    contexts:
      - name: default
        context:
          cluster: default
          namespace: ${project.namespace}
          user: ${name}-deployer
    current-context: default
    users:
      - name: ${name}-deployer
        user:
          token: $token
    KUBECONFIG

    chmod 640 /etc/k8s/deploy-${name}.kubeconfig
    chown root:deploy /etc/k8s/deploy-${name}.kubeconfig
    echo "Deploy credentials for ${name} ready."
  '';

in
{
  # Deploy user — SSH-only, no login shell
  users.users.deploy = {
    isSystemUser = true;
    group = "deploy";
    shell = "${pkgs.shadow}/bin/nologin";
    openssh.authorizedKeys.keys = lib.mapAttrsToList mkAuthorizedKey projects;
  };

  users.groups.deploy = { };

  # Systemd oneshot to generate kubeconfigs after K3s starts
  systemd.services.generate-deploy-kubeconfigs = {
    description = "Generate namespace-scoped kubeconfigs for deploy users";
    after = [ "k3s.service" ];
    requires = [ "k3s.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = setupScript;
      RemainAfterExit = true;
    };
    # K3s API needs a moment to become ready after the service starts
    preStart = ''
      for i in $(seq 1 60); do
        if ${kubectl} --kubeconfig=/etc/rancher/k3s/k3s.yaml cluster-info &>/dev/null; then
          exit 0
        fi
        sleep 2
      done
      echo "K3s API not ready after 120s" >&2
      exit 1
    '';
  };
}
