{
  config,
  lib,
  inputs,
  pkgs,
  ...
}: {
  programs.gpg = {
    enable = true;
    homedir = "${config.home.homeDirectory}/private/gpg";
  };

  services.gpg-agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-gnome3;
    # Increase ttl from 2hr to 24hr;
    defaultCacheTtl = 86400;
    maxCacheTtl = 86400;
  };
}
