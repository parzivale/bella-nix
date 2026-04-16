{
  flake.modules.nixos.cinny = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.home.packages = [pkgs.cinny-desktop];

    preservation.preserveAt."/persistent".users.${user} = {
      directories = [
        {
          directory = ".local/share/cinny";
          mode = "0700";
        }
      ];
    };
  };
}
