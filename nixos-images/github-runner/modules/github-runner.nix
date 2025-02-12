{ config, lib, pkgs, ... }: {

  environment.etc.github-pat-runner1.source = ../secrets/secret-runner1;
  environment.etc.github-pat-runner2.source = ../secrets/secret-runner2;

  services.github-runners = {
    runner-homelab-iac = {
      enable = true;
      name = "runner-homelab-iac";
      tokenFile = "/etc/github-pat-runner1";
      url = "https://github.com/kmjayadeep/homelab-iac";
      extraLabels = [ "nixos" "cosmos" ];
      extraPackages = with pkgs; [
        busybox
        nodejs_22
      ];
    };
    runner-near-dns = {
      enable = false;
      name = "runner-near-dns";
      tokenFile = "/etc/github-pat-runner2";
      url = "https://github.com/kmjayadeep/near-dns";
      extraLabels = [ "nixos" "cosmos" ];
      extraPackages = with pkgs; [
        busybox
        nodejs_22
        curl
        cargo
      ];
    };
  };

}

