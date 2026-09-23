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
    inputs@{
      nixpkgs,
      haumea,
      flake-parts,
      agenix-rekey,
      self,
      ...
    }:
    let
      vars = import ./vars.nix;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      # Every module file is loaded as a keyed stub around its path rather than as
      # a bare path. `key` is what the module system dedupes and reports on, and a
      # repo-relative name ("modules/programs/git.nix") reads better there than the
      # store path a bare path keys itself by. The key must *not* be that path
      # string: the module system keeps only the first module for a given key, so
      # an identical key would shadow the very import it wraps.
      wrapModule = src: path: {
        key = "${baseNameOf src}/${nixpkgs.lib.removePrefix "${toString src}/" (toString path)}";
        imports = [ path ];
      };

      flattenModules =
        tree: nixpkgs.lib.collect (x: x ? key && x ? imports && builtins.isList x.imports) tree;

      load =
        src:
        haumea.lib.load {
          inherit src;
          loader = [ (haumea.lib.matchers.nix (_: wrapModule src)) ];
        };

      mkSystemForHost =
        hostName:
        nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit vars hostName;
          };
          modules = [
            inputs.self.modules.nixos.${hostName}
          ];
        };

      # finix ships `finixSystem`, but it evaluates with `class = "nixos"`,
      # which gives up the one check worth having once two module sets live in
      # the same flake: nothing would stop a `modules.nixos` module being
      # imported into a finix host, and it would fail later as a pile of missing
      # options rather than at the import that caused it. Evaluate under
      # `class = "finix"` instead — finix's own modules declare no class of
      # their own, so they are content either way — and a mismatched import is
      # rejected on the spot. This otherwise mirrors `finixSystem`: same default
      # module, same `modules` specialArg, same pkgs/lib passthrough.
      mkFinixForHost =
        hostName:
        let
          eval = nixpkgs.lib.evalModules {
            class = "finix";
            specialArgs = {
              modules = inputs.finix.nixosModules;
              inherit vars hostName;
            };
            modules = [
              inputs.finix.nixosModules.default
              inputs.self.modules.finix.${hostName}
            ];
          };
        in
        eval
        // {
          inherit (eval._module.args) pkgs;
          inherit (nixpkgs) lib;
        };

      hostSystem = hostName: self.nixosConfigurations.${hostName}.pkgs.stdenv.hostPlatform.system;

      mkDeployForHost = hostName: {
        hostname = hostName + "." + vars.tailscale_dns;
        profiles.system.path =
          inputs.deploy-rs.lib.${hostSystem hostName}.activate.nixos
            self.nixosConfigurations.${hostName};
      };

      # finix runs finit as pid 1, so `activate.nixos` is wrong twice over: it
      # reads `boot.loader.systemd-boot.enable`, an option finix does not
      # declare, and it looks for the closure at `system.build.toplevel` where
      # finix keeps it at `system.topLevel`. The switch script it installs takes
      # the same switch|boot|test verbs, so drive that directly.
      mkFinixDeployForHost = hostName: {
        hostname = hostName + "." + vars.tailscale_dns;
        profiles.system.path =
          inputs.deploy-rs.lib.${hostSystem hostName}.activate.custom
            self.nixosConfigurations.${hostName}.config.system.topLevel
            "$PROFILE/bin/switch-to-configuration switch";
      };

      mkHosts =
        { nixos, finix }:
        {
          nixosConfigurations =
            nixpkgs.lib.genAttrs nixos mkSystemForHost // nixpkgs.lib.genAttrs finix mkFinixForHost;

          deploy = {
            sshUser = vars.username;
            user = "root";
            interactiveSudo = false;
            nodes =
              nixpkgs.lib.genAttrs nixos mkDeployForHost // nixpkgs.lib.genAttrs finix mkFinixDeployForHost;
            confirmTimeout = 120;
            activationTimeout = 180;
          };

          # Only the systems we actually build for: deploy-rs's `lib` covers every
          # system it supports (darwin, i686, ...), and mapping over all of it
          # emitted checks for platforms this flake has no hosts on.
          checks = nixpkgs.lib.genAttrs systems (
            system:
            let
              deployLib = inputs.deploy-rs.lib.${system};

              # Both checks take the node's profile path as a build input, so an
              # unfiltered `deploy` would make every system's checks drag in every
              # other host's closure — building the aarch64 macbook and the desktop
              # closure just to check embla.
              nodesHere = nixpkgs.lib.filterAttrs (hostName: _: hostSystem hostName == system) self.deploy.nodes;

              checksFor = nodes: deployLib.deployChecks (self.deploy // { inherit nodes; });
            in
            {
              inherit (checksFor nodesHere) deploy-schema;
            }
            # One activation check per host, so a failure names the host and a
            # rebuild of one host doesn't invalidate the others' checks.
            // nixpkgs.lib.mapAttrs' (
              hostName: node:
              nixpkgs.lib.nameValuePair "deploy-activate-${hostName}"
                (checksFor {
                  ${hostName} = node;
                }).deploy-activate
            ) nodesHere
          );
        };

      # Hosts are split by the module system that evaluates them: everything
      # under `nixos/` goes through nixpkgs' nixosSystem, everything under
      # `finix/` through its own evalModules. Both sides land in
      # `nixosConfigurations`, so deploy-rs and the checks treat them alike.
      hosts = {
        nixos = load ./src/hosts/nixos;
        finix = load ./src/hosts/finix;
      };
      modules = load ./src/modules;
    in
    flake-parts.lib.mkFlake
      {
        inherit inputs;
      }
      {
        imports = [
          inputs.agenix-rekey.flakeModule

          # `flake.modules`, declared here rather than taken from
          # inputs.flake-parts.flakeModules.modules, for one reason: upstream's
          # wrapper carries `_class` and `_file` but no `key` — its source has a
          # literal "TODO: set key?". Without one, a module reached through two
          # importers (lazygit, via both `cli` and `desktop`) is anonymous twice
          # over, so the module system keys it by each parent, evaluates it
          # twice and merges its list-valued definitions twice. Giving it a key
          # derived from its own name collapses the two back into one.
          #
          # The key can't be added on top of upstream's declaration: it attaches
          # `_class`/`_file` through the option's `apply`, and mergeOptionDecls
          # refuses a second declaration that also sets `apply`.
          (
            { lib, moduleLocation, ... }:
            let

              addInfo =
                class: name:
                let
                  ident = "${toString moduleLocation}#modules.${lib.strings.escapeNixIdentifier class}.${lib.strings.escapeNixIdentifier name}";
                  # `generic` is the one class that must not be stamped onto the
                  # module — its whole purpose is to stay usable from any class.
                  # That is the only part of this wrapper it has to skip, which
                  # is why upstream passes generic modules through untouched and
                  # they lose the metadata as collateral. A key constrains
                  # nothing, so it can carry one either way.
                  class' = lib.optionalAttrs (class != "generic") { _class = class; };
                in
                module:
                # A function, not a plain set, so it is taken as a full module
                # even where submodule shorthand applies (flake-parts#326).
                { ... }:
                class'
                // {
                  _file = ident;
                  key = ident;
                  imports = [ module ];
                };
            in
            {
              options.flake.modules = lib.mkOption {
                type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.deferredModule);
                description = "Groups of modules published by the flake, keyed by class.";
                apply = lib.mapAttrs (class: lib.mapAttrs (addInfo class));
              };
            }
          )
        ]
        ++ flattenModules modules
        ++ (nixpkgs.lib.mapAttrsToList (name: value: {
          flake.modules.nixos.${name}.imports = [
            (import ./lib.nix)
            inputs.self.modules.nixos.base
            inputs.disko.nixosModules.disko
            inputs.agenix.nixosModules.default
            inputs.agenix-rekey.nixosModules.default
            inputs.nix-flatpak.nixosModules.nix-flatpak
            inputs.chaotic.nixosModules.default
            {
              nixpkgs.overlays = [
                # niri-flake (as of rev 9ee3e13) still builds against libdisplay-info_0_2,
                # which nixpkgs removed. niri's libdisplay-info-sys crate pins the pkg-config
                # library to >=0.1.0, <0.3.0, so 0.3+ won't do — pull the real 0.2 package
                # from a pinned pre-removal nixpkgs.
                (final: prev: {
                  libdisplay-info_0_2 =
                    (import inputs.nixpkgs-libdisplay-info {
                      inherit (prev.stdenv.hostPlatform) system;
                    }).libdisplay-info_0_2;
                })
                inputs.niri-flake.overlays.niri
                inputs.gtnh-nix.overlays.default
                inputs.nixos-apple-silicon.overlays.default
                inputs.nix-minecraft.overlay
              ];
              networking.hostName = "${name}";
              home-manager.sharedModules = [ ];
            }
          ]
          ++ builtins.map (
            module:
            module
            // {
              imports = builtins.map (
                dep: inputs.flake-parts.lib.importApply dep { inherit inputs; }
              ) module.imports;
            }
          ) (flattenModules value);
        }) hosts.nixos)
        # finix hosts get a much thinner wrapper: nothing above is a finix
        # module. disko, agenix, chaotic, nix-flatpak and `base` are all written
        # against nixpkgs' NixOS module set, and `lib.nix` aliases
        # `services.nginx.virtualHosts`, so none of them evaluate here. finix
        # supplies its own defaults through `nixosModules.default`, which
        # `finixSystem` imports for us.
        ++ (nixpkgs.lib.mapAttrsToList (name: value: {
          flake.modules.finix.${name}.imports = [
            { networking.hostName = "${name}"; }
          ]
          ++ builtins.map (
            module:
            module
            // {
              imports = builtins.map (
                dep: inputs.flake-parts.lib.importApply dep { inherit inputs; }
              ) module.imports;
            }
          ) (flattenModules value);
        }) hosts.finix);

        inherit systems;

        flake = mkHosts (builtins.mapAttrs (_: builtins.attrNames) hosts);

        perSystem =
          {
            config,
            pkgs,
            system,
            lib,
            ...
          }:
          {
            agenix-rekey.nixosConfigurations = inputs.self.nixosConfigurations; # (not technically needed, as it is already the default)

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
