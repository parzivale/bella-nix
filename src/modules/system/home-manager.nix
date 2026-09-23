{ inputs, ... }:
let
  # The user's own config, which is what home-manager is for. Everything here
  # is `programs.*`, `home.*` and `xdg.*` - the parts that mean the same thing
  # wherever they are evaluated.
  home =
    { config, ... }:
    let
      user = config.systemConstants.username;
    in
    {
      home-manager.users.${user} = {
        programs.home-manager.enable = true;

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
