{ config, lib, pkgs, ... }: {

  networking = {
    hostName = "chillyfries";
    interfaces.ens18 = {
      ipv4.addresses = [{
        address = "192.168.1.76";
        prefixLength = 24;
      }];
      ipv6.addresses = [{
        address = "fe80::176";
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
    serverName = "valheim-homelab-chillyfries";
    extraArgs = [
      "-modifier deathpenalty casual"
      "-modifier raids none"
      "-modifier resources most"
      "-setkey StaminaRate 50"
      "-modifier portals casual"
    ];
  };

  environment.etc.restic-env.source = ../secrets/chillyfries/secret-restic.env;
}
