# Flake-level helpers: how modules and hosts are found on disk, how each host
# is evaluated, and the deploy-rs nodes and checks built from them.
#
# `systems` is the flake's own list, from flake.nix; it is only read here.
{ inputs, systems }:
let
  inherit (inputs) nixpkgs self;
  inherit (nixpkgs) lib;
in
rec {
  vars = import ./vars.nix;

  # Every module file is loaded as a keyed stub around its path rather than as
  # a bare path. `key` is what the module system dedupes and reports on, and a
  # repo-relative name ("modules/programs/git.nix") reads better there than the
  # store path a bare path keys itself by. The key must *not* be that path
  # string: the module system keeps only the first module for a given key, so
  # an identical key would shadow the very import it wraps.
  #
  # `module` is what actually gets imported: the path itself for an ordinary
  # module, or the path already applied to its arguments for a host file.
  # The key always comes from the path, so both kinds read the same.
  wrapModule = src: module: path: {
    key = "${baseNameOf src}/${lib.removePrefix "${toString src}/" (toString path)}";
    imports = [ module ];
  };

  # Every `.nix` file under `src`, at any depth. Anything else (facter.json,
  # host keys, firmware blobs) is skipped.
  nixFiles = src: builtins.filter (lib.hasSuffix ".nix") (lib.filesystem.listFilesRecursive src);

  # The directories directly under `dir`, as `readDir` gives them. The filter
  # is what keeps `.gitkeep` and other stray files out.
  subdirs = dir: lib.filterAttrs (_: type: type == "directory") (builtins.readDir dir);

  # Every module under `src` as a flat list of wrapped modules. These are
  # flake-parts modules, called with flake-parts' own arguments.
  loadModules = src: map (path: wrapModule src path path) (nixFiles src);

  # One entry per host directory directly under `src`, keyed by hostname.
  # Host files are written as
  # `{ inputs }: <nixos module>`, so they are applied here, once, as they are
  # loaded.
  loadHosts =
    src:
    lib.mapAttrs (
      name: _:
      let
        dir = src + "/${name}";
      in
      map (path: wrapModule src (inputs.flake-parts.lib.importApply path { inherit inputs; }) path) (
        nixFiles dir
      )
    ) (subdirs src);

  # Hosts are split by the module system that evaluates them: each directory
  # under `src/hosts` is a class, and the hosts inside it are evaluated by that
  # class's entry in `builders` - nixpkgs' nixosSystem for `nixos/`, our
  # `finixSystem` for `finix/`. Both sides land in `nixosConfigurations`, so
  # deploy-rs and the checks treat them alike. A class directory with no
  # entry in `builders` fails at `mkHost`.
  hosts = lib.mapAttrs (class: _: loadHosts (./src/hosts + "/${class}")) (subdirs ./src/hosts);
  modules = loadModules ./src/modules;

  # Both classes get the same wrapper: `base`, and whatever the host itself
  # imports. Everything a NixOS host needs beyond that — the user, nix
  # settings, resolved, disko, agenix — is a module it asks for by name, so a
  # finix host is not handed a pile of nixpkgs-only modules it cannot
  # evaluate. finix supplies its own defaults through `nixosModules.default`,
  # which `finixSystem` imports for us.
  hostModules = lib.concatLists (
    lib.mapAttrsToList (
      class:
      lib.mapAttrsToList (
        name: files: {
          flake.modules.${class}.${name}.imports = [ self.modules.generic.base ] ++ files;
        }
      )
    ) hosts
  );

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
  flakeModulesOption =
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
    };

  # finix's counterpart to `lib.nixosSystem`: the same `{ specialArgs, modules }`
  # in, the same evaluation-plus-`pkgs`/`lib` out, so the two classes differ
  # only in which of the two `mkHost` calls.
  #
  # finix ships a `finixSystem` of its own, but it evaluates with
  # `class = "nixos"`, which gives up the one check worth having once two
  # module sets live in the same flake: nothing would stop a `modules.nixos`
  # module being imported into a finix host, and it would fail later as a
  # pile of missing options rather than at the import that caused it.
  # Evaluate under `class = "finix"` instead — finix's own modules declare no
  # class of their own, so they are content either way — and a mismatched
  # import is rejected on the spot. This otherwise mirrors upstream's: same
  # default module, same `modules` specialArg, same pkgs/lib passthrough.
  #
  # Two different `modules` meet here: `args.modules` is the caller's module
  # list, while the `modules` specialArg is finix's module set, which hosts
  # import from as `modules.facter` and the like.
  finixSystem =
    args@{
      specialArgs ? { },
      modules,
    }:
    let
      eval = lib.evalModules {
        class = "finix";
        specialArgs = specialArgs // {
          modules = inputs.finix.nixosModules;
        };
        modules = [
          inputs.finix.nixosModules.default

          # Which nixpkgs a machine is evaluated against is a fact about
          # this flake, not about the machine, so it is said once here.
          # The host says what it is, with `nixpkgs.hostPlatform`.
          { nixpkgs.source = inputs.nixpkgs; }
        ]
        ++ args.modules;
      };
    in
    eval
    // {
      inherit (eval._module.args) pkgs;
      inherit lib;
    };

  # One builder per host class, i.e. per directory under `src/hosts`. This is
  # the list of classes that exist: a class directory missing from it fails
  # at `mkHost`.
  builders = {
    nixos = lib.nixosSystem;
    finix = finixSystem;
  };

  mkHost =
    class: hostName:
    (builders.${class} or (throw "lib.nix: no builder for host class `${class}` (src/hosts/${class})"))
      {
        specialArgs = { inherit vars hostName; };
        modules = [ self.modules.${class}.${hostName} ];
      };

  hostSystem = hostName: self.nixosConfigurations.${hostName}.pkgs.stdenv.hostPlatform.system;

  # One deployment path for both classes. finix is activated by nixos' own
  # activation script because it answers the two questions that script asks:
  # `system.build.toplevel` and `boot.loader.systemd-boot.enable` both come
  # from its nixos-compat module, the second added upstream for this.
  mkDeployForHost = hostName: {
    hostname = hostName + "." + vars.tailscale_dns;
    profiles.system.path =
      inputs.deploy-rs.lib.${hostSystem hostName}.activate.nixos
        self.nixosConfigurations.${hostName};
  };

  # The flake's `nixosConfigurations`, `deploy` and `checks`, for every host
  # found under `src/hosts`.
  hostOutputs = mkHosts (builtins.mapAttrs (_: builtins.attrNames) hosts);

  mkHosts = classes: {
    nixosConfigurations = lib.concatMapAttrs (class: names: lib.genAttrs names (mkHost class)) classes;

    deploy = {
      sshUser = vars.username;
      user = "root";
      interactiveSudo = false;

      # Prefixed verbatim to every privileged command, with `user` glued
      # on the end - so what runs is `sudo <wrapper> root <command>`.
      # deploy-rs documents this setting as "must accept at least two
      # arguments: user name to execute commands as and the rest is the
      # command to execute", which is the wrapper's argument protocol.
      # It is what gives sudoers a fixed path to name, and what gets the
      # closure's signature checked before activate-rs runs. See
      # `deploy-user`.
      sudo = "sudo /run/current-system/sw/bin/deploy-activate";

      nodes = lib.genAttrs (lib.concatLists (lib.attrValues classes)) mkDeployForHost;
      confirmTimeout = 120;
      activationTimeout = 180;
    };

    # Only the systems we actually build for: deploy-rs's `lib` covers every
    # system it supports (darwin, i686, ...), and mapping over all of it
    # emitted checks for platforms this flake has no hosts on.
    checks = lib.genAttrs systems (
      system:
      let
        deployLib = inputs.deploy-rs.lib.${system};

        # Both checks take the node's profile path as a build input, so an
        # unfiltered `deploy` would make every system's checks drag in every
        # other host's closure — building the aarch64 macbook and the desktop
        # closure just to check embla.
        nodesHere = lib.filterAttrs (hostName: _: hostSystem hostName == system) self.deploy.nodes;

        checksFor = nodes: deployLib.deployChecks (self.deploy // { inherit nodes; });
      in
      {
        inherit (checksFor nodesHere) deploy-schema;
      }
      # One activation check per host, so a failure names the host and a
      # rebuild of one host doesn't invalidate the others' checks.
      // lib.mapAttrs' (
        hostName: node:
        lib.nameValuePair "deploy-activate-${hostName}"
          (checksFor {
            ${hostName} = node;
          }).deploy-activate
      ) nodesHere
    );
  };
}
