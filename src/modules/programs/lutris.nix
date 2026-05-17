{inputs, ...}: {
  flake.modules.homeManager.lutris = {pkgs, ...}: {
    programs.lutris = {
        enable = true;
        package = pkgs.lutris.override {
          extraLibraries = pkgs:
            with pkgs; [
              libGL
              vulkan-loader
            ];
        };
        winePackages = [pkgs.wineWow64Packages.stagingFull];
        defaultWinePackage = pkgs.wineWow64Packages.stagingFull;
    };
  };

  flake.modules.nixos.lutris = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.imports = [inputs.self.modules.homeManager.lutris];

    preservation.preserveAt."/persistent".users.${user}.directories = [
      {directory = "/Games";}
    ];
  };
}
