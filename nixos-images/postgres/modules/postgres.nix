{ config, lib, pkgs, ... }: {

  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    package = pkgs.postgresql_16;
    extraPlugins = with pkgs.postgresql_16.pkgs; [ pgvector ];
    ensureDatabases = [
      "planka"
      "totp"
      "immich"
      "coder"
      "shoppinglist"
      "uptimekuma"
      "taskplanner"
    ];
    ensureUsers = [
      {
        name = "planka";
        ensureDBOwnership = true;
      }
      {
        name = "totp";
        ensureDBOwnership = true;
      }
      {
        name = "immich";
        ensureDBOwnership = true;
      }
      {
        name = "coder";
        ensureDBOwnership = true;
      }
      {
        name = "shoppinglist";
        ensureDBOwnership = true;
      }
      {
        name = "uptimekuma";
        ensureDBOwnership = true;
      }
      {
        name = "taskplanner";
        ensureDBOwnership = true;
      }
      {
        name = "pgweb";
      }
    ];
    authentication = pkgs.lib.mkOverride 10 ''
      #type database DBuser origin-address    auth-method
      local all      all                      trust
      # lan ipv4
      host  all      all    192.168.1.1/24    scram-sha-256
      # Dockge hosts
      host  all      all    172.25.0.0/16    scram-sha-256
    '';
  };

}
