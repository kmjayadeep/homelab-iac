{ config, lib, pkgs, ... }: {

  networking = {
    hostName = "titania-worker1";
    interfaces.ens18 = {
      ipv4.addresses = [{
        address = "192.168.1.78";
        prefixLength = 24;
      }];
      ipv6.addresses = [{
        address = "fe80::78";
        prefixLength = 64;
      }];
    };
    defaultGateway = {
      address = "192.168.1.1";
      interface = "ens18";
    };
  };
}
