# NixOS specific modules - placeholder for future NixOS laptop
{ pkgs, ... }:
{
  # Example NixOS-specific configuration
  # Uncomment and customize when setting up your NixOS laptop

  # Boot configuration
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  # networking.networkmanager.enable = true;

  # Sound
  # services.pulseaudio.enable = true;
  # OR use pipewire
  # services.pipewire = {
  #   enable = true;
  #   alsa.enable = true;
  #   pulse.enable = true;
  # };

  # Enable OpenGL
  # hardware.graphics.enable = true;

  # Time zone (same as darwin)
  time.timeZone = "Europe/Helsinki";

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
  ];

  # Enable zsh
  programs.zsh.enable = true;

  # Enable the X11 windowing system (optional, for GUI)
  # services.xserver.enable = true;
  # services.xserver.displayManager.gdm.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;
}
