{ config, lib, pkgs, ... }: {

  services.k3s = {
    package = pkgs.k3s_1_31;
    enable = true;
    role = "agent";
    serverAddr = "https://192.168.1.40:6443";
    tokenFile = "/etc/k3s-token";
    extraFlags = toString [
      "--kubelet-arg=allowed-unsafe-sysctls=net.ipv6.*,net.ipv4.*"
    ];
  };

  environment.etc.k3s-token.source = ../secrets/secret-k3s-token;
}
