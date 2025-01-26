{ config, lib, pkgs, ... }: {

  networking = {
    hostName = "valkyrie";
    interfaces.ens18 = {
      ipv4.addresses = [{
        address = "192.168.1.79";
        prefixLength = 24;
      }];
      ipv6.addresses = [{
        address = "fe80::179";
        prefixLength = 64;
      }];
    };
    defaultGateway = {
      address = "192.168.1.1";
      interface = "ens18";
    };
  };

  services.valheim = {
    worldName =  "NoMapHardcore";
    serverName = "valheim-homelab-valkyrie";
    extraArgs = [
      "-modifier combat veryhard"
      "-modifier raids more"
      "-modifier resources most"
      "-modifier portals hard"
      "-setkey StaminaRate 50"
      "-setkey nomap"
    ];
  };

  environment.etc.restic-env.source = ../secrets/valkyrie/secret-restic.env;
}
