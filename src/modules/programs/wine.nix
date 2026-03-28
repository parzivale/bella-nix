{
  flake.modules.nixos.wine = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.home.packages = with pkgs; [
      fex-headless
      wineWow64Packages.stagingFull
    ];

    preservation.preserveAt."/persistent".users.${user}.directories = [
      {directory = ".wine";}
    ];
  };
}
