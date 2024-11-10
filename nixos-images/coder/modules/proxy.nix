{ config, pkgs, lib, ... }:

{
  services.nginx = {
    enable = true;
    virtualHosts."coder.cosmos.cboxlab.com" = {
      # Set up the reverse proxy
      locations."/" = {
        proxyPass = "http://localhost:3000";
        proxyWebsockets = true;
      };
      enableACME = true; # Automatically use the ACME certificate
      forceSSL = true;
    };
  };

  environment.etc.cloudflare-api-token.source = ../secrets/secret-cloudflare-api-token;

  # Enable the ACME (Let's Encrypt) service
  security.acme = {
    acceptTerms = true;
    defaults.email = lib.strings.fileContents ../secrets/secret-acme-email;

    certs."coder.cosmos.cboxlab.com" = {
      dnsProvider = "cloudflare";
      environmentFile = "/etc/cloudflare-api-token";
      webroot = null; # Explicitely disable webroot for DNS challenge
    };
  };
}

