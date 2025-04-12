{ config, lib, pkgs, ... }: {

  virtualisation.oci-containers.containers = {
    pihole = {
      image = "pihole/pihole:2025.04.0";
      ports = [
        "153:53/udp"
        "153:53/tcp"
        "180:80/tcp"
        "1443:443/tcp"
      ];
      environment = {
        TZ = "Europe/Zurich"; # Change to your timezone
        DNS1 = "1.1.1.1";
        DNS2 = "1.0.0.1";
        ServerIP = "192.168.1.250"; # Change to your NixOS machine IP
      };
      # volumes = [
      #   "/var/lib/pihole/etc-pihole:/etc/pihole"
      #   "/var/lib/pihole/etc-dnsmasq.d:/etc/dnsmasq.d"
      # ];
      extraOptions = [ "--cap-add=NET_ADMIN" ];
    };
  };

}

