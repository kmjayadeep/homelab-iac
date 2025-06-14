{ config, pkgs, lib, ... }:

{
  services.nginx = {
    enable = true;
    clientMaxBodySize = "100m";
    recommendedProxySettings = true; # Add X- headers
    virtualHosts."gatekeeper.cosmos.cboxlab.com" = {
      # Set up the reverse proxy
      locations."/" = {
        proxyPass = "http://127.0.0.1:3000";
      };
      enableACME = true; # Automatically use the ACME certificate
      forceSSL = true;
    };
    virtualHosts."jellyfin-public.cosmos.cboxlab.com" = {
      # Set up the reverse proxy
      locations."/" = {
        proxyPass = "https://192.168.1.80:443";
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

    certs."gatekeeper.cosmos.cboxlab.com" = {
      dnsProvider = "cloudflare";
      environmentFile = "/etc/cloudflare-api-token";
      webroot = null; # Explicitely disable webroot for DNS challenge
    };
    certs."jellyfin-public.cosmos.cboxlab.com" = {
      dnsProvider = "cloudflare";
      environmentFile = "/etc/cloudflare-api-token";
      webroot = null; # Explicitely disable webroot for DNS challenge
    };
  };
}

