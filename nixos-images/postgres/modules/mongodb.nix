{ config, lib, pkgs, ... }: {

  environment.etc.mongodb-password.source = ../secrets/secret-mongodb-password;

  services.mongodb =  {
    enable = true;
    package = pkgs.mongodb-ce; # 8.0.4 at the moment
    bind_ip = "0.0.0.0";
    enableAuth = true;
    initialRootPasswordFile = "/etc/mongodb-password";
  };

}
