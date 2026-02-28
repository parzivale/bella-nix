{
  flake.modules.nixos.prismlauncher = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.home.packages = [pkgs.prismlauncher];

    preservation.preserveAt."/persistent".users.${user}.directories = [".local/share/PrismLauncher"];
  };
}
