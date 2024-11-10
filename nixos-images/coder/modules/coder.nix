{ config, lib, pkgs, ... }: {

  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
  };

  services.coder = {
    enable = true;
    listenAddress = "0.0.0.0:3000";
    accessUrl = "http://coder.cosmos.cboxlab.com:3000";
    group = "docker";
    database = {
      createLocally = false;
      host = "postgres.cosmos.cboxlab.com";
      username = "coder";
      password = lib.strings.fileContents ../secrets/secret-db-password;
    };
  };

  environment.systemPackages = with pkgs; [
    coder
  ];

}
