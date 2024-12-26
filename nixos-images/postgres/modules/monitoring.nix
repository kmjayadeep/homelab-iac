{ config, lib, pkgs, ... }: {
  # Node exporter
  services.prometheus.exporters = {
    node.enable = true;
    postgres.enable = true;
  };
}
