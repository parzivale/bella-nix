{
  description = "Bella nix configs";

  # Inputs
  # https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake.html#flake-inputs
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Pinned to the last nixpkgs rev that still provides libdisplay-info_0_2, which
    # niri-flake requires (niri's libdisplay-info-sys demands >=0.1.0, <0.3.0) but
    # which nixpkgs has since removed. Drop once niri-flake moves to libdisplay-info 0.3+.
    nixpkgs-libdisplay-info.url = "github:nixos/nixpkgs/753cc8a3a87467296ddd1fa93f0cc3e81120ee46";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      # flake-parts only reads `.lib` off this, which nixpkgs provides too — so
      # point it at ours instead of fetching a separate nixpkgs.lib tree.
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    niri-unstable = {
      url = "github:YaLTeR/niri";
      # Consumed purely as a source tree by niri-flake; its own nixpkgs would
      # otherwise be a second full tree in the lock for nothing.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Deliberately NOT following our nixpkgs: chaotic-nyx's binary cache is built
    # against their own pinned nixpkgs rev, so letting this follow ours would cause
    # cache misses and force a from-source kernel build.
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    agenix = {
      url = "github:yaxitech/ragenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Unused: programs/wezterm.nix uses the nixpkgs wezterm — the `package`
    # override pointing at this fork is commented out there. Re-enable both
    # together.
    # wezterm = {
    #   url = "github:parzivale/wezterm?dir=nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    agenix-rekey = {
      url = "github:parzivale/agenix-rekey";
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

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        niri-unstable.follows = "niri-unstable";
        # niri-flake only touches nixpkgs-stable in its own checks and cache job
        # (packages.all-niri-flake-packages) — nothing we consume. Collapse it
        # rather than locking a third nixpkgs.
        nixpkgs-stable.follows = "nixpkgs";
      };
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager = {
          follows = "home-manager";
          inputs.nixpkgs.follows = "nixpkgs";
        };
      };
    };

    # Unused: services/walker.nix isn't imported by any host (desktop uses
    # fuzzel). Uncomment both — walker needs elephant to follow — to bring the
    # launcher back.
    # elephant = {
    #   url = "github:abenz1267/elephant";
    #   inputs = {
    #     nixpkgs.follows = "nixpkgs";
    #   };
    # };
    # walker = {
    #   url = "github:abenz1267/walker";
    #   inputs = {
    #     nixpkgs.follows = "nixpkgs";
    #     elephant = {
    #       follows = "elephant";
    #       inputs = {
    #         nixpkgs.follows = "nixpkgs";
    #       };
    #     };
    #   };
    # };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gtnh-nix = {
      url = "github:parzivale/gtnh-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
      };
    };

    nixos-apple-silicon = {
      url = "github:nix-community/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    preservation.url = "github:nix-community/preservation";

    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    playit-nixos-module = {
      url = "github:pedorich-n/playit-nixos-module";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
      };
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak";

    # Declares no inputs of its own (it pins nixpkgs through lon for its
    # formatter only), so there is nothing to make follow ours.
    finix.url = "github:parzivale/finix/generic-services";

    # Likewise, and on the branch where its modules declare their units through
    # `providers.services` rather than finit directly - which is what makes them
    # usable on a finix host of ours at all.
    community-modules.url = "github:parzivale/community-modules/generic-services";

    jev-bot = {
      url = "github:parzivale/jev-bot";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    xdg-desktop-portal-termfilepickers = {
      url = "github:Guekka/xdg-desktop-portal-termfilepickers";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
        treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      inherit (import ./lib.nix { inherit inputs systems; })
        modules
        hostModules
        flakeModulesOption
        hostOutputs
        ;
    in
    flake-parts.lib.mkFlake
      {
        inherit inputs;
      }
      {
        imports = [
          inputs.agenix-rekey.flakeModule
          flakeModulesOption
        ]
        ++ modules
        ++ hostModules;

        inherit systems;

        flake = hostOutputs;

        perSystem =
          {
            config,
            pkgs,
            system,
            lib,
            ...
          }:
          {
            # Defaults to all of `nixosConfigurations`, and agenix-rekey refuses to
            # run while any node lacks the agenix module - so the ones without it
            # have to come out. Which is not the same as "the finix ones": a finix
            # host importing `secrets` has `age.rekey` like any other, and excluding
            # it by class meant Cerberus quietly had no secrets rekeyed for it the
            # moment it moved. What is actually being asked is whether the node has
            # the module, so that is what this asks.
            agenix-rekey.nixosConfigurations = lib.filterAttrs (
              _: node: node.config ? age
            ) inputs.self.nixosConfigurations;
            formatter = pkgs.nixfmt-tree;

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
                  statix
                  deadnix
                  nixfmt-tree
                  xray
                  (pkgs.runCommand "bnix" { nativeBuildInputs = [ pkgs.nushell ]; } ''
                    cp -r ${inputs.self} $out
                    chmod -R u+w $out
                    mv $out/scripts $out/bin
                    mv $out/bin/mod.nu $out/bin/bnix
                    chmod +x $out/bin/bnix
                    patchShebangs $out/bin/bnix
                  '')
                ];
              };
            };
          };
      };
}
