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
          ./modules/user.nix
          ./modules/tailscale.nix
          ./hosts/jd-vm.nix
        ];
      };

    };
}
