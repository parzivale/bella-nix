{inputs, ...}: {
  flake.modules.homeManager.wine = {pkgs, ...}: {
    home.packages = with pkgs; [
      fex-headless
      wineWow64Packages.stagingFull
    ];
  };

  flake.modules.nixos.wine = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.imports = [inputs.self.modules.homeManager.wine];

    preservation.preserveAt."/persistent".users.${user}.directories = [
      {directory = ".wine";}
    ];
  };
}
