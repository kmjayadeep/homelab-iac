{ config, lib, pkgs, ... }: {

  services.adguardhome = {
    enable = true;

    # Following options are modified manually at
    # /var/lib/AdGuardHome/AdGuardHome.yaml
    host = "127.0.0.1";
    port = 3000;
  };

}

