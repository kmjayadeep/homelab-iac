{ config, lib, pkgs, ... }: {

  environment.etc.k3s-env.source = ../secrets/secret-k3s-env;

  services.k3s = {
    package = pkgs.k3s_1_33;
    enable = true;
    role = "server";
    # environmentFile = "/etc/k3s-env";
    extraFlags = toString [
      # "--datastore-endpoint=$K3S_DATASTORE_ENDPOINT"
      "--cluster-init"
      "--disable traefik"
      "--disable servicelb"
      "--disable metrics-server"
      "--disable-cloud-controller"
      "--kube-controller-manager-arg=--node-cidr-mask-size-ipv6=112"
      "--kube-proxy-arg proxy-mode=ipvs"
      "--cluster-cidr=10.42.0.0/16,2001:cafe:42::/96"
      "--service-cidr=10.43.0.0/16,2001:cafe:43::/112"
      "--snapshotter native"
      "--disable-network-policy"
      "--node-ip=192.168.1.40,fe80::ccc"
      "--disable local-storage"
      "--disable-helm-controller"
      "--write-kubeconfig /home/operator/.kube/config"
      "--flannel-backend=none"
      "--write-kubeconfig-mode 644"
      "--kubelet-arg=allowed-unsafe-sysctls=net.ipv6.*,net.ipv4.*"
    ];
  };
}

