{
  flake.modules.nixos.stylix = {
    pkgs,
    config,
    ...
  }: {
    stylix = {
      enable = true;
      image = config.systemConstants.bg_img;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
      cursor = {
        package = pkgs.nordzy-cursor-theme;
        name = "Nordzy-cursors";
        size = 32;
      };
    };
  };
}
