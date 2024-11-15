{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # My bash scripts
    scripts = {
      url = "github:kmjayadeep/scripts";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { home-manager, nixpkgs, ... }@inputs: let
    system = "x86_64-linux"; #current system
  in
    {
      nixosConfigurations.jd-vm = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./configuration.nix
          ./modules/docker.nix
          ./modules/ssh.nix
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
                scripts = inputs.scripts.packages.${system};
              };
              users.jayadeep = ./home;
            };
          }
        ];
      };

    };
}
