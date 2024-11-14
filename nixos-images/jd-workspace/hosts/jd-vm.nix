{ config, lib, pkgs, ... }: {

  networking = {
    hostName = "jd-cloud";
    interfaces.ens18 = {
      ipv4.addresses = [{
        address = "192.168.1.74";
        prefixLength = 24;
      }];
      ipv6.addresses = [{
        address = "fe80::174";
        prefixLength = 64;
      }];
    };
    defaultGateway = {
      address = "192.168.1.1";
      interface = "ens18";
    };
  };

}
