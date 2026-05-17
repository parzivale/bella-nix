{inputs, ...}: {
  flake.modules.homeManager.cinny = {pkgs, ...}: {
    home.packages = [pkgs.cinny-desktop];
  };

  flake.modules.nixos.cinny = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.imports = [inputs.self.modules.homeManager.cinny];

    preservation = config.helpers.mkPreserve user {
      directories = [{directory = ".local/share/cinny"; mode = "0700";}];
    };
  };
}
