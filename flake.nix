{
  description = "Bella nix configs";

  # Inputs
  # https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake.html#flake-inputs

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    agenix = {
      url = "github:yaxitech/ragenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix-rekey = {
      url = "github:oddlama/agenix-rekey";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    haumea = {
      url = "github:nix-community/haumea/v0.2.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    haumea,
    ...
  }: let
    vars = import ./vars.nix;

    mkSystems = hosts: src: let
      src = haumea.lib.load {
        inherit src;
        inputs = {
          inherit nixpkgs;
          specialArgs = {inherit inputs vars;};
        };
        loader = [
          (haumea.matchers.nix haumea.loaders.default)
          (haumea.matchers.always haumea.loaders.path)
        ];
      };
    in
      nixpkgs.lib.mapAttrs (hostname: hostInfo: {
        hostname = nixpkgs.lib.nixosSystem {
          specialArgs = {inherit inputs vars;};
          modules = [
            src
            hostInfo
            inputs.stylix.nixosModules.stylix
            inputs.home-manager.nixosModules.default
            inputs.nixos-facter-modules.nixosModules.facter
            inputs.agenix.nixosModules.default
            inputs.agenix-rekey.nixosModules.default
            inputs.ucodenix.nixosModules.default
            inputs.disko.nixosModules.disko
            {config.facter.reportPath = hostInfo."facter.json";}
            {networking.hostName = "${hostname}";}
          ];
        };
      })
      (haumea.lib.load {
        src = hosts;
        inputs = {
          inherit nixpkgs;
          specialArgs = {inherit inputs vars;};
        };
        loader = [
          (haumea.matchers.nix haumea.loaders.default)
          (haumea.matchers.always haumea.loaders.path)
        ];
      });
  in {
    nixosConfigurations = mkSystems ./src/hosts ./src/common;

    agenix-rekey = inputs.agenix-rekey.configure {
      userFlake = self;
      nixosConfigurations = self.nixosConfigurations;
    };
  };
}
