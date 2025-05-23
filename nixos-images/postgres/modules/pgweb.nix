{ config, lib, pkgs, ... }: {

  environment.systemPackages = with pkgs; [
    pgweb
  ];

  environment.etc.pgweb-env.source = ../secrets/secret-pgweb.env;

  systemd.services.pgweb = {
    enable = true;
    wantedBy = ["multi-user.target"];
    description = "Postgres visualizer";

    script = ''
      source /etc/pgweb-env
      ${pkgs.pgweb}/bin/pgweb --url postgresql://pgweb:$POSTGRES_PASSWORD@192.168.1.77:5432/postgres?sslmode=disable --bind 127.0.0.1
    '';

  };

}
