{ config, lib, pkgs, ... }: {

  environment.etc.github-pat.source = ../secrets/secret-pat;

  services.github-runners = {
    cosmos = {
      enable = true;
      name = "cosmos";
      tokenFile = "/etc/github-pat";
      url = "https://github.com/kmjayadeep/homelab-iac";
    };
  };

}

