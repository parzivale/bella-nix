{
  flake.modules.nixos.osu = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.home.packages = [pkgs.osu-lazer-bin];

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
