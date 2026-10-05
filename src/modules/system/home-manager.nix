{ inputs, ... }:
let
  # The user's own config, which is what home-manager is for. Everything here
  # is `programs.*`, `home.*` and `xdg.*` - the parts that mean the same thing
  # wherever they are evaluated.
  home =
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      home-manager.users.${user} = {
        programs.home-manager.enable = true;

        # Telling home-manager what `nix.settings.use-xdg-base-directories` already made
        # true, because on finix it cannot find that out for itself.
        #
        # `home.profileDirectory` is computed and read-only, in descending priority:
        # `/etc/profiles/per-user/<name>` when home-manager is a submodule installing
        # packages externally, else `${xdg.stateHome}/nix/profile` when `nix.useXdg`, else
        # `~/.nix-profile`. And `useXdg` is itself computed, the last of its three sources
        # being `osConfig.nix.settings.use-xdg-base-directories`.
        #
        # That is the detection, and it cannot fire here: finix has no `nix.settings` at all,
        # the setting living under `services.nix-daemon.settings`. So home-manager asks a
        # question finix does not answer, gets nothing, and falls through to `~/.nix-profile`
        # - a path which does not exist on this machine, because `nix-env -i` wrote the
        # profile to ~/.local/state/nix/profile like the setting asked it to.
        #
        # Everything derived from `profileDirectory` was therefore pointing at nothing:
        # QT_PLUGIN_PATH, QML2_IMPORT_PATH, fontconfig's font directories, NIX_DEBUG_INFO_DIRS,
        # and the hm-session-vars.sh that nushell sources.
        #
        # `assumeXdg` is the documented way to say it by hand - its description names this
        # exact case, "intended for settings in which use-xdg-base-directories is set
        # globally". It changes nothing about nix's behaviour; it stops home-manager guessing
        # wrong about it.
        #
        # A no-op on the nixos side, where `useUserPackages` wins the first branch and the
        # profile is /etc/profiles/per-user/<name> regardless. Said here rather than in the
        # finix module because the fact is true of both: the same `settings` block in
        # modules/system/nix.nix sets use-xdg-base-directories for either class.
        nix.assumeXdg = true;

        xdg.userDirs =
          let
            dump = "${config.home-manager.users.${user}.home.homeDirectory}/dmp";
          in
          {
            setSessionVariables = false;
            enable = true;
            createDirectories = true;
            desktop = dump;
            documents = dump;
            download = dump;
            music = dump;
            pictures = dump;
            templates = dump;
            videos = dump;
            publicShare = dump;
            projects = dump;
          };
      };
    };
in
{
  flake.modules.nixos.home-manager = {
    imports = [
      home
      inputs.home-manager.nixosModules.default
    ];

    home-manager = {
      backupFileExtension = "bak";

      useGlobalPkgs = true;
      useUserPackages = true;
    };
  };

  flake.modules.finix.home-manager = {
    imports = [
      home
      inputs.community-modules.nixosModules.home-manager
    ];

    # No `useGlobalPkgs`, `useUserPackages` or `backupFileExtension` to set.
    # The first two are how it works there rather than options: the module
    # evaluates against the system's `pkgs` and puts each user's profile in
    # `users.users.<name>.packages`. The third has no counterpart, so an
    # existing file in the way is the activation's problem rather than
    # something moved aside.
    #
    # The larger difference is what a user config may contain: there is no
    # systemd user session here, so `systemd.user.services` and anything built
    # on it does nothing. `programs.*`, `home.file` and `home.packages` are the
    # usable surface, which is most of what these modules set - but not all of
    # it, and a module that relies on a user service should say so rather than
    # appearing to work.
  };
}
