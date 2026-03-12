{
  flake.modules.nixos.karere = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.home.packages = [pkgs.karere];

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
