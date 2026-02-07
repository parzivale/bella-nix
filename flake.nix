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

    disktui = {
      url = "github:parzivale/disktui";
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

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    preservation.url = "github:nix-community/preservation";
  };

  outputs = inputs @ {
    nixpkgs,
    haumea,
    flake-parts,
    agenix-rekey,
    deploy-rs,
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
            inputs.agenix.nixosModules.default
            inputs.agenix-rekey.nixosModules.default
            inputs.disko.nixosModules.disko
            inputs.preservation.nixosModules.preservation
            {
              networking.hostName = "${hostName}";
            }
          ]
          ++ (flattenModules common) ++ (flattenModules hostInfo);
      };

    mkDeployForHost = hostName: hostInfo: let
      nixConf = self.nixosConfigurations;
      getSystem = hostName: nixConf.${hostName}.pkgs.stdenv.hostPlatform.system;
    in {
      hostname = hostName + "." + vars.tailscale_dns;
      profiles.system.path = deploy-rs.lib.${(getSystem hostName)}.activate.nixos self.nixosConfigurations.${hostName};
    };

    mkFlake = hosts: src: let
      commonModules = load src;
      hostsModules = load hosts;
    in {
      nixosConfigurations =
        nixpkgs.lib.mapAttrs (mkSystemForHost commonModules)
        hostsModules;

      deploy = {
        sshUser = vars.username;
        user = "root";
        interactiveSudo = true;
        nodes = nixpkgs.lib.mapAttrs mkDeployForHost hostsModules;
      };

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
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

      flake = mkFlake ./src/hosts ./src/common;

      perSystem = {
        config,
        pkgs,
        system,
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
              age-plugin-fido2-hmac
              nixos-anywhere
              pkgs.deploy-rs
            ];

            nativeBuildInputs = [
              config.agenix-rekey.package
            ];

            shellHook = ''
              exec nu -I '${inputs.self}' -e "use scripts/mod.nu *"
            '';
          };
        };
      };
    };
}
