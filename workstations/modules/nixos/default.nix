# NixOS system configuration
{ pkgs, ... }:
{
  # Boot
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
  };

  # Locale
  time.timeZone = "Europe/Helsinki";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_TIME = "fi_FI.UTF-8";
      LC_MONETARY = "fi_FI.UTF-8";
    };

    # Input method (Chinese Pinyin)
    inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5.addons = with pkgs; [
        qt6Packages.fcitx5-chinese-addons
      ];
    };
  };

  # Networking
  networking.networkmanager.enable = true;
  networking.nameservers = [
    "1.1.1.1"
    "8.8.8.8"
  ];

  hardware = {
    # Bluetooth
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    # GPU (Intel Iris Xe)
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  services = {
    blueman.enable = true;

    # Audio (PipeWire)
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # Login manager
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd 'uwsm start hyprland-uwsm.desktop'";
          user = "greeter";
        };
      };
    };

    # Power management
    thermald.enable = true;
    auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "powersave";
          turbo = "never";
        };
        charger = {
          governor = "performance";
          turbo = "auto";
        };
      };
    };
  };

  # Docker
  virtualisation.docker.enable = true;

  # Security
  security.polkit.enable = true;
  security.rtkit.enable = true; # for PipeWire

  # Fonts
  fonts.packages = with pkgs; [
    inter
    roboto-mono
    noto-fonts
    noto-fonts-cjk-sans
    nerd-fonts.symbols-only
  ];

  # XDG portal for screen sharing, file pickers, etc.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    gnumake
    wl-clipboard
    brightnessctl
    playerctl
  ];

  programs = {
    # Hyprland with UWSM (systemd integration)
    hyprland = {
      enable = true;
      withUWSM = true;
    };

    # Enable zsh system-wide (needed for user shell)
    zsh.enable = true;

    # Steam
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
    };
  };

  # Allow unfree
  nixpkgs.config.allowUnfree = true;

  # Nix settings
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # CachyOS kernel binary cache
    substituters = [ "https://attic.xuyh0120.win/lantian" ];
    trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
  };
}
