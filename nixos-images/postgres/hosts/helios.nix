{ config, lib, pkgs, ... }: {

  networking = {
    hostName = "helios";
    interfaces.ens18 = {
      ipv4 = {
        addresses = [{
          address = "192.168.1.77";
          prefixLength = 24;
        }];
        routes = [{
          address = "10.42.1.0";
          prefixLength = 24;
          via = "192.168.1.79";
        }];
      };
      ipv6.addresses = [{
        address = "fe80::77";
        prefixLength = 64;
      }];
    };
    defaultGateway = {
      address = "192.168.1.1";
      interface = "ens18";
    };
  };

}

