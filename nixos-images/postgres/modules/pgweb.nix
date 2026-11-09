{ config, lib, pkgs, ... }: {

  environment.systemPackages = with pkgs; [
    pgweb
  ];

  environment.etc.pgweb-env.source = ../secrets/secret-pgweb.env;

  systemd.services.pgweb = {
    enable = true;
    wantedBy = ["multi-user.target"];
    after = ["postgresql.service"];
    requires = ["postgresql.service"];
    description = "Postgres visualizer";

    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "5s";
    };

    script = ''
      source /etc/pgweb-env
      ${pkgs.pgweb}/bin/pgweb --url postgresql://pgweb:$POSTGRES_PASSWORD@192.168.1.77:5432/postgres?sslmode=disable --bind 127.0.0.1
    '';

  };

}
