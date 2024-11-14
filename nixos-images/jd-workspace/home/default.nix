{
  config,
  lib,
  inputs,
  ...
}: {
  home.stateVersion = "24.05";

  imports = [
    ./packages.nix
    ./shell.nix
  ];
}

