{
  config,
  lib,
  inputs,
  ...
}: {
  home.stateVersion = "24.05";

  imports = [
    ./nvim
    ./taskwarrior

    ./git.nix
    ./gpg.nix
    ./kubernetes.nix
    ./packages.nix
    ./pass.nix
    ./shell.nix
    ./syncthing.nix
  ];
}

