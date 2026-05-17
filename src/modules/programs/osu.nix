{inputs, ...}: {
  flake.modules.homeManager.osu = {pkgs, ...}: {
    home.packages = [pkgs.osu-lazer-bin];
  };

  flake.modules.nixos.osu = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.imports = [inputs.self.modules.homeManager.osu];

    preservation.preserveAt."/persistent".users.${user} = {
      directories = [
        {
          directory = ".local/share/osu";
          mode = "0755";
        }
      ];
    };
  };
}
