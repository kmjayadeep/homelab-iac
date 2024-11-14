{
  config,
  pkgs,
  inputs,
  ...
}: {
  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
  };
}

