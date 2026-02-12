{vars, ...}: let
  user = vars.username;
in {
  flake.modules.bella.home-manager = {
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
