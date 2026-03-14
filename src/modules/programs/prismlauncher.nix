{
  flake.modules.nixos.prismlauncher = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    # nix-ld provides /lib64/ld-linux-x86-64.so.2 for MCEF's libcef.so
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [nss nspr libgbm];
    };

    home-manager.users.${user}.home.packages = [
      (pkgs.prismlauncher.override {
        additionalLibs = with pkgs; [nss nspr libgbm];
      })
    ];

    preservation.preserveAt."/persistent".users.${user}.directories = [
      {
        directory = ".local/share/PrismLauncher";
        mode = "0755";
      }
    ];
  };
}
