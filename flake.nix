{
  description = "Bella nix configs";

  # Inputs
  # https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake.html#flake-inputs

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

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
    nixpkgs,
    haumea,
    flake-parts,
    agenix-rekey,
    self,
    ...
  }: let
    vars = import ./vars.nix;

    flattenModules = tree:
      nixpkgs.lib.collect
      (x: nixpkgs.lib.isPath x)
      tree;

    load = src:
      haumea.lib.load {
        inherit src;
        loader = [(haumea.lib.matchers.nix haumea.lib.loaders.path)];
      };

    mkSystemForHost = common: hostName: hostInfo:
      nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs vars hostName;
        };
        modules =
          [
            inputs.stylix.nixosModules.stylix
            inputs.home-manager.nixosModules.default
            inputs.nixos-facter-modules.nixosModules.facter
            inputs.agenix.nixosModules.default
            inputs.agenix-rekey.nixosModules.default
            inputs.disko.nixosModules.disko
            {
              networking.hostName = "${hostName}";
            }
          ]
          ++ (flattenModules common) ++ (flattenModules hostInfo);
      };

    mkSystems = hosts: src: let
      commonModules = load src;
      hostsModules = load hosts;
    in
      nixpkgs.lib.mapAttrs (mkSystemForHost commonModules)
      hostsModules;
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        agenix-rekey.flakeModule
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      flake.nixosConfigurations = mkSystems ./src/hosts ./src/common;

      perSystem = {
        config,
        pkgs,
        ...
      }: {
        agenix-rekey.nixosConfigurations = self.nixosConfigurations;

        devShells = {
          default = pkgs.mkShell {
            packages = with pkgs; [
              nushell
              age
              openssl
              coreutils
              avahi
            ];

            nativeBuildInputs = [
              config.agenix-rekey.package
            ];

            shellHook = ''
              exec nu -e "use scripts *"
            '';
          };
        };
      };
    };
}
