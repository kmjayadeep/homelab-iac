{
  pkgs,
  inputs,
  ...
}: {
  services = {
    syncthing = {
      enable = true;
    };
  };
}
