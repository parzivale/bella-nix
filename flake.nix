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

    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake/feat/hm-module-sine-reusing-src-and-bootloader-everywhere";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager = {
          follows = "home-manager";
          inputs.nixpkgs.follows = "nixpkgs";
        };
      };
    };

    elephant = {
      url = "github:abenz1267/elephant";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    walker = {
      url = "github:abenz1267/walker";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        elephant = {
          follows = "elephant";
          inputs = {
            nixpkgs.follows = "nixpkgs";
          };
        };
      };
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    bash-env-nushell = {
      url = "github:tesujimath/bash-env-nushell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    preservation.url = "github:nix-community/preservation";
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

    mkSystemForHost = hostName:
      nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit vars hostName;
        };
        modules = [
          inputs.self.modules.nixos.${hostName}
        ];
      };

    mkDeployForHost = hostName: let
      nixConf = self.nixosConfigurations;
      getSystem = hostName: nixConf.${hostName}.pkgs.stdenv.hostPlatform.system;
    in {
      hostname = hostName + "." + vars.tailscale_dns;
      profiles.system.path = inputs.deploy-rs.lib.${(getSystem hostName)}.activate.nixos self.nixosConfigurations.${hostName};
    };

    mkHosts = hostNames: {
      nixosConfigurations =
        nixpkgs.lib.genAttrs hostNames mkSystemForHost;

      deploy = {
        sshUser = vars.username;
        user = "root";
        interactiveSudo = true;
        nodes = nixpkgs.lib.genAttrs hostNames mkDeployForHost;
      };

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) inputs.deploy-rs.lib;
    };

    hosts = load ./src/hosts;
    modules = load ./src/modules;
  in
    flake-parts.lib.mkFlake {
      inherit inputs;
    } {
      imports =
        [
          inputs.flake-parts.flakeModules.modules
          inputs.agenix-rekey.flakeModule
        ]
        ++ flattenModules modules
        ++ (nixpkgs.lib.mapAttrsToList (name: value: {
            flake.modules.nixos.${name}.imports =
              [
                inputs.self.modules.nixos.base
                inputs.disko.nixosModules.disko
                inputs.agenix.nixosModules.default
                inputs.agenix-rekey.nixosModules.default
                {
                  nixpkgs.overlays = [
                    inputs.niri-flake.overlays.niri
                    (final: prev: {
                      bash-env-nushell = prev.stdenv.mkDerivation {
                        name = "bash-env-nushell-wrapped";
                        src = inputs.bash-env-nushell.packages.${prev.system}.default;
                        dontUnpack = true;
                        installPhase = ''
                          mkdir -p $out/bin
                          cp $src/bash-env.nu $out/bin/bash-env.nu
                        '';
                        meta.mainProgram = "bash-env-nushell";
                      };
                    })
                  ];
                  networking.hostName = "${name}";
                  home-manager.sharedModules = [];
                }
              ]
              ++ builtins.map (dep: inputs.flake-parts.lib.importApply dep {inherit inputs;}) (flattenModules value);
          })
          hosts);

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      flake = mkHosts (builtins.attrNames hosts);

      perSystem = {
        config,
        pkgs,
        system,
        lib,
        ...
      }: {
        agenix-rekey.nixosConfigurations = inputs.self.nixosConfigurations; # (not technically needed, as it is already the default)

        devShells = {
          default = pkgs.mkShell {
            nativeBuildInputs = [
              config.agenix-rekey.package
            ];

            packages = with pkgs; [
              nushell
              age
              openssl
              coreutils
              avahi
              age-plugin-fido2-hmac
              nixos-anywhere
              deploy-rs
            ];

            shellHook = ''
              exec nu -I '${inputs.self}' -e "use scripts/mod.nu *"
            '';
          };
        };
      };
    };
}
