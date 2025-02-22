{ config, lib, pkgs, ... }: {

  environment.etc.cloudflare-creds.source = ../secrets/secret-cloudflare;


  services.cloudflared = {
    enable = true;
    tunnels = {
      "60fe5dbf-3372-4806-8108-1364cd8219cc" = {
        credentialsFile = "/etc/cloudflare-creds";
        ingress = {
          "taskplanner.cboxlab.com" = "https://taskplanner.cosmos.cboxlab.com";
        };
        default = "http_status:404";
      };
    };
  };

}

