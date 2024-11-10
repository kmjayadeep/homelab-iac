{ config, lib, pkgs, ... }: {

  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
  };

  services.coder = {
    enable = true;
    listenAddress = "127.0.0.1:3000";
    accessUrl = "https://coder.cosmos.cboxlab.com";
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
