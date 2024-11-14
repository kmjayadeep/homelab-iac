{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };
  outputs = { nixpkgs, ... }:
    {
      nixosConfigurations.jd-vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          ./modules/docker.nix
          ./modules/system.nix
          ./modules/tailscale.nix
          ./modules/user.nix
          ./hosts/jd-vm.nix
        ];
      };

    };
}
