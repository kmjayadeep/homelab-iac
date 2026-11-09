{ config, lib, pkgs, ... }: {
  # Node exporter
  services.prometheus.exporters = {
    node = {
      enable = true;
      enabledCollectors = [ "systemd" ];
    };
    postgres.enable = true;
  };
}
