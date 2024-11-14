{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { home-manager, nixpkgs, ... }@inputs:
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
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useUserPackages = true;
              useGlobalPkgs = true;
              backupFileExtension = "back";
              extraSpecialArgs = {
                inherit inputs;
              };
              users.jayadeep = ./home;
            };
          }
        ];
      };

    };
}
