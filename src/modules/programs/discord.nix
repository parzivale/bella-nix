{
  flake.modules.nixos.discord = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user} = {
      programs.discord = {
        enable = true;
        package = pkgs.discord-canary;
      };
    };
  };
}
