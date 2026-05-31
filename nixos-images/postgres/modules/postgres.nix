{ config, lib, pkgs, ... }:

let
  catalog = import ./postgres-catalog.nix;
  databaseNames = builtins.attrNames catalog.databases;
  databaseUsers = lib.mapAttrsToList
    (name: database: {
      name = database.owner;
      ensureDBOwnership = true;
    })
    catalog.databases;
  extraUsers = map (user: { name = user.name; }) catalog.extraUsers;
in
{
  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    package = pkgs.postgresql_16;
    extraPlugins = with pkgs.postgresql_16.pkgs; [ pgvector ];
    ensureDatabases = databaseNames;
    ensureUsers = databaseUsers ++ extraUsers;
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
