{ config, pkgs, ... }:

let
  manifestDir = "/var/lib/rancher/k3s/server/manifests";

  traefikChart = pkgs.writeText "traefik-helmchart.yaml" ''
    apiVersion: helm.cattle.io/v1
    kind: HelmChart
    metadata:
      name: traefik
      namespace: kube-system
    spec:
      chart: traefik
      repo: https://traefik.github.io/charts
      targetNamespace: traefik
      createNamespace: true
      version: 39.0.2
      valuesContent: |-
        deployment:
          strategy:
            type: Recreate
        service:
          type: ClusterIP
        ports:
          web:
            hostPort: 80
            http:
              redirections:
                entryPoint:
                  to: websecure
                  scheme: https
          websecure:
            hostPort: 443
  '';

  certManagerChart = pkgs.writeText "cert-manager-helmchart.yaml" ''
    apiVersion: helm.cattle.io/v1
    kind: HelmChart
    metadata:
      name: cert-manager
      namespace: kube-system
    spec:
      chart: cert-manager
      repo: https://charts.jetstack.io
      targetNamespace: cert-manager
      createNamespace: true
      valuesContent: |-
        crds:
          enabled: true
  '';

  argocdChart = pkgs.writeText "argocd-helmchart.yaml" ''
    apiVersion: helm.cattle.io/v1
    kind: HelmChart
    metadata:
      name: argocd
      namespace: kube-system
    spec:
      chart: argo-cd
      repo: https://argoproj.github.io/argo-helm
      targetNamespace: argocd
      createNamespace: true
      version: 9.0.5
      valuesContent: |-
        configs:
          params:
            server.insecure: "true" # TLS terminated by Traefik ingress
  '';

  argocdBootstrap = pkgs.writeText "argocd-bootstrap.yaml" ''
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: bootstrap
      namespace: argocd
    spec:
      project: default
      source:
        repoURL: https://github.com/MikaelSiidorow/infra.git
        targetRevision: main
        path: k8s/apps
      destination:
        server: https://kubernetes.default.svc
        namespace: argocd
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
  '';

  # Host service endpoints — managed by NixOS instead of ArgoCD because
  # ArgoCD excludes Endpoints/EndpointSlice resources by default.
  headscaleService = pkgs.writeText "headscale-service.yaml" ''
    apiVersion: v1
    kind: Namespace
    metadata:
      name: headscale
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: headscale
      namespace: headscale
    spec:
      ports:
        - port: 8080
          targetPort: 8080
    ---
    apiVersion: discovery.k8s.io/v1
    kind: EndpointSlice
    metadata:
      name: headscale
      namespace: headscale
      labels:
        kubernetes.io/service-name: headscale
    addressType: IPv4
    ports:
      - port: 8080
    endpoints:
      - addresses:
          - 10.42.0.1
  '';

  refineryDbService = pkgs.writeText "refinery-db-service.yaml" ''
    apiVersion: v1
    kind: Service
    metadata:
      name: refinery-db
      namespace: refinery
    spec:
      ports:
        - port: 5432
          targetPort: 5432
    ---
    apiVersion: discovery.k8s.io/v1
    kind: EndpointSlice
    metadata:
      name: refinery-db
      namespace: refinery
      labels:
        kubernetes.io/service-name: refinery-db
    addressType: IPv4
    ports:
      - port: 5432
    endpoints:
      - addresses:
          - 10.42.0.1
  '';

  clusterIssuer = pkgs.writeText "cluster-issuer.yaml" ''
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt-prod
    spec:
      acme:
        server: https://acme-v02.api.letsencrypt.org/directory
        email: mikael@siidorow.com
        privateKeySecretRef:
          name: letsencrypt-prod-account-key
        solvers:
          - http01:
              ingress:
                ingressClassName: traefik
  '';
in
{
  # K3s - Lightweight Kubernetes
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = toString [
      "--disable=traefik"   # Deploy our own Traefik via HelmChart CRD
      "--disable=servicelb" # Use hostPort instead of Klipper LB for source IP preservation
    ];
  };

  # Auto-deploy infrastructure manifests via K3s
  systemd.tmpfiles.rules = [
    "L+ ${manifestDir}/traefik-helmchart.yaml - - - - ${traefikChart}"
    "L+ ${manifestDir}/cert-manager-helmchart.yaml - - - - ${certManagerChart}"
    "L+ ${manifestDir}/cluster-issuer.yaml - - - - ${clusterIssuer}"
    "L+ ${manifestDir}/argocd-helmchart.yaml - - - - ${argocdChart}"
    "L+ ${manifestDir}/argocd-bootstrap.yaml - - - - ${argocdBootstrap}"
    "L+ ${manifestDir}/headscale-service.yaml - - - - ${headscaleService}"
    "L+ ${manifestDir}/refinery-db-service.yaml - - - - ${refineryDbService}"
  ];

  # Ensure k3s can manage iptables
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # Alias for convenience
  environment.shellAliases = {
    k = "kubectl";
  };

  # Kubeconfig for root
  environment.variables = {
    KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
  };
}
