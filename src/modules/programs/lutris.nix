{
  flake.modules.nixos.lutris = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user} = {
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
    preservation.preserveAt."/persistent".users.${user} = {
      directories = [
        {
          directory = "/Games";
        }
      ];
    };
  };
}
