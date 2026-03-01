{inputs, ...}: {
  flake.modules.nixos.home-manager = {config, ...}: let
    user = config.systemConstants.username;
  in {
    imports = [
      inputs.home-manager.nixosModules.default
    ];
    home-manager = {
      backupFileExtension = "bak";

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
          userDirs = let
            dump = "${config.home-manager.users.${user}.home.homeDirectory}/dmp";
          in {
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
          };
        };
      };
    };
  };
}
