{
  flake.modules.nixos.prismlauncher = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.home.packages = [
      (pkgs.prismlauncher.override {additionalLibs = with pkgs; [nss nspr libgbm];})
    ];

    preservation.preserveAt."/persistent".users.${user}.directories = [
      {
        directory = ".local/share/PrismLauncher";
        mode = "0755";
      }
    ];
  };
}
