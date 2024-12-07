{ config, lib, pkgs, ... }: {

  networking = {
    hostName = "gatekeeper";
    interfaces.ens18 = {
      ipv4.addresses = [{
        address = "192.168.1.250";
        prefixLength = 24;
      }];
      ipv6.addresses = [{
        address = "fe80::250";
        prefixLength = 64;
      }];
    };
    defaultGateway = {
      address = "192.168.1.1";
      interface = "ens18";
    };
  };

}
