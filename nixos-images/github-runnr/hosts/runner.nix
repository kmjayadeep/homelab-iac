{ config, lib, pkgs, ... }: {

  networking = {
    hostName = "runner";
    interfaces.ens18 = {
      ipv4.addresses = [{
        address = "192.168.1.75";
        prefixLength = 24;
      }];
      ipv6.addresses = [{
        address = "fe80::175";
        prefixLength = 64;
      }];
    };
    defaultGateway = {
      address = "192.168.1.1";
      interface = "ens18";
    };
  };

}
