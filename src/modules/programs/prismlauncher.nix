{
  flake.modules.nixos.prismlauncher = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.home.packages = [pkgs.prismlauncher];

    # nix-ld provides libs to unpatched binaries like MCEF's libcef.so
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [nss nspr libgbm libdrm expat libxkbcommon dbus alsa-lib];
    };

    preservation.preserveAt."/persistent".users.${user}.directories = [
      {
        directory = ".local/share/PrismLauncher";
        mode = "0755";
      }
    ];
  };
}
