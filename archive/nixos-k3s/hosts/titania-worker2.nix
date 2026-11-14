{ config, lib, pkgs, ... }: {

  networking = {
    hostName = "titania-worker2";
    interfaces.ens18 = {
      ipv4.addresses = [{
        address = "192.168.1.79";
        prefixLength = 24;
      }];
      ipv6.addresses = [{
        address = "fe80::79";
        prefixLength = 64;
      }];
    };
    defaultGateway = {
      address = "192.168.1.1";
      interface = "ens18";
    };
  };

}
