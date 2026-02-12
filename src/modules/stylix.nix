{
  pkgs,
  vars,
  ...
}: {
  flake.modules.bella.stylix = {
    stylix = {
      enable = true;
      image = vars.bg_img;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
      cursor = {
        package = pkgs.nordzy-cursor-theme;
        name = "Nordzy-cursors";
        size = 32;
      };
    };
  };
}
