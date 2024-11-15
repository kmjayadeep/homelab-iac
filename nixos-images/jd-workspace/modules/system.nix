{ config, lib, pkgs, ... }: {

  programs.zsh.enable = true;

  # Set neovim as default editor
  programs.neovim.defaultEditor = true;

  environment.systemPackages = with pkgs; [
    htop
    greetd.tuigreet
    git
    neovim
    wget
    kitty
    wireguard-tools # Wg-quick
    nfs-utils
    gnumake
    lynx

    # others
    iperf
    rar
  ];

  # Remove unecessary preinstalled packages
  environment.defaultPackages = [];

  # Port 7681
  services.ttyd= {
    enable = true;
    writeable = true;
  };
}

