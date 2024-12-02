{ config, lib, pkgs, ... }: {

  networking = {
    hostName = "golem";
    interfaces.ens18 = {
      ipv4.addresses = [{
        address = "192.168.1.81";
        prefixLength = 24;
      }];
      ipv6.addresses = [{
        address = "fe80::181";
        prefixLength = 64;
      }];
    };
    defaultGateway = {
      address = "192.168.1.1";
      interface = "ens18";
    };
  };

}
