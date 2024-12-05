{ config, lib, pkgs, ... }: {

  environment.etc.github-pat.source = ../secrets/secret-pat;

  services.github-runners = {
    runner = {
      enable = true;
      name = "runner";
      tokenFile = "/etc/github-pat";
      url = "https://github.com/kmjayadeep/homelab-iac";
      extraLabels = [ "nixos" "cosmos" ];
      extraPackages = with pkgs; [
        busybox
        nodejs_22
      ];
    };
  };

}

