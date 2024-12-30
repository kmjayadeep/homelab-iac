{ config, lib, pkgs, ... }: {

  services.k3s = {
    enable = true;
    role = "agent";
    serverAddr = "https://192.168.1.40:6443";
    tokenFile = "/etc/k3s-token";
  };

  environment.etc.k3s-token.source = ../secrets/secret-k3s-token;
}