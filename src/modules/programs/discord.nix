{inputs, ...}: {
  flake.modules.homeManager.discord = {pkgs, ...}: {
    home.sessionVariables.NIXOS_OZONE_WL = "1";
    programs.discord = {
      enable = true;
      package = pkgs.discord-canary;
    };
  };

  flake.modules.nixos.discord = {config, ...}: let
    user = config.systemConstants.username;
  in {
    preservation.preserveAt."/persistent".users.${user} = {
      directories = [
        {
          directory = ".config/discordcanary";
        }
      ];
    };

    xdg.portal = {
      enable = true;
    };

    home-manager.users.${user}.imports = [inputs.self.modules.homeManager.discord];
  };
}
