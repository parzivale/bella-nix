{
  flake.modules.nixos.home-manager = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;

      users.${user} = {
        programs = {
          home-manager.enable = true;
        };
        home = {
          username = "${user}";
        };
        xdg = {
          userDirs = {
            enable = true;
            createDirectories = true;
          };
        };
      };
    };
  };
}
