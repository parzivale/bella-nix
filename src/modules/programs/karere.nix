{inputs, ...}: {
  flake.modules.homeManager.karere = {pkgs, ...}: {
    home.packages = [pkgs.karere];
  };

  flake.modules.nixos.karere = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.imports = [inputs.self.modules.homeManager.karere];

    preservation.preserveAt."/persistent".users.${user} = {
      directories = [
        {
          directory = ".local/share/karere";
          mode = "0700";
        }
      ];
    };
  };
}
