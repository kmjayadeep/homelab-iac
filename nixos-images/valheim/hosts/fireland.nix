{ config, lib, pkgs, ... }: {

  networking = {
    hostName = "fireland";
    interfaces.ens18 = {
      ipv4.addresses = [{
        address = "192.168.1.70";
        prefixLength = 24;
      }];
      ipv6.addresses = [{
        address = "fe80::170";
        prefixLength = 64;
      }];
    };
    defaultGateway = {
      address = "192.168.1.1";
      interface = "ens18";
    };
  };

  services.valheim = {
    worldName =  "DARKLAND";
    serverName = "valheim-homelab-fireland";
  };

}
