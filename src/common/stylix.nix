{
  pkgs,
  vars,
  ...
}: {
  stylix = {
    enable = true;
    image = ../../assets/wallhaven-8ge2x1_3840x2160.png;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
    cursor = {
      package = pkgs.nordzy-cursor-theme;
      name = "Nordzy-cursors";
      size = 32;
    };
  };
}
