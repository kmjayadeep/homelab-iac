{
  pkgs,
  inputs,
  lib,
  ...
}: {
  services = {
    syncthing = {
      enable = true;
      extraOptions = [
        "--gui-address=0.0.0.0:8384"
      ];
    };
  };
}
