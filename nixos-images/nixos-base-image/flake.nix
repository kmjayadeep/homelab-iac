{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, nixos-generators, ... }: {
    packages.x86_64-linux = {
      proxmox = nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        modules = [
          # you can include your own nixos configuration here, i.e.
          ./configuration.nix
        ];
        format = "proxmox";
      };
    };
  };
}
