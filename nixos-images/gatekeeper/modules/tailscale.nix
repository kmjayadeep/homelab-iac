{
  config,
  pkgs,
  ...
}: {
  boot.kernel.sysctl = {
    "fs.inotify.max_user_instances" = 1024;

    # Need for tailscale
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  services.tailscale = {
    enable = true;
    extraSetFlags = [
      "--accept-dns=false"
      "--advertise-routes=192.168.1.0/24"
    ];
    extraUpFlags = [
      "--accept-dns=false"
      "--advertise-routes=192.168.1.0/24"
    ];
  };

}
