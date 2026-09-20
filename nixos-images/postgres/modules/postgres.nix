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
  extensionCommands = lib.concatMap
    (databaseName:
      map
        (extension: ''
          ${pkgs.postgresql_16}/bin/psql -v ON_ERROR_STOP=1 -d ${lib.escapeShellArg databaseName} -c ${lib.escapeShellArg "CREATE EXTENSION IF NOT EXISTS \"${extension}\";"}
        '')
        catalog.databases.${databaseName}.extensions)
    databaseNames;
  extraUsers = map (user: { name = user.name; }) catalog.extraUsers;
in
{
  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    package = pkgs.postgresql_16;
    extensions = with pkgs.postgresql_16.pkgs; [ pgvector ];
    ensureDatabases = databaseNames;
    ensureUsers = databaseUsers ++ extraUsers;
    authentication = pkgs.lib.mkOverride 10 ''
      #type database DBuser origin-address    auth-method
      local all      all                      trust
      # lan ipv4
      host  all      all    192.168.1.1/24    scram-sha-256
      # Kubernetes pod network
      host  all      all    10.42.0.0/16     scram-sha-256
      # Dockge hosts
      host  all      all    172.25.0.0/16    scram-sha-256
    '';
  };

  systemd.services.postgresql-extensions = {
    description = "Enable PostgreSQL extensions declared in the database catalog";
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
    };
    script = lib.concatStringsSep "\n" extensionCommands;
  };
}
