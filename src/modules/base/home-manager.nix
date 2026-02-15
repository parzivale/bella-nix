{inputs, ...}: {
  flake.modules.nixos.home-manager = {config, ...}: let
    user = config.systemConstants.username;
  in {
    imports = [
      inputs.home-manager.nixosModules.default
    ];
    home-manager = {
      home-manager.backupFileExtension = "bak";

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
