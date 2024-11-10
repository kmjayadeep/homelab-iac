{ config, lib, pkgs, ... }: {

  networking = {
    hostName = "coder";
    interfaces.ens18 = {
      ipv4.addresses = [{
        address = "192.168.1.72";
        prefixLength = 24;
      }];
      ipv6.addresses = [{
        address = "fe80::172";
        prefixLength = 64;
      }];
    };
    defaultGateway = {
      address = "192.168.1.1";
      interface = "ens18";
    };
  };

}
