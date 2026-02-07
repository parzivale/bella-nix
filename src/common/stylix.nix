{
  pkgs,
  vars,
  ...
}: {
  stylix = {
    enable = true;
    image = pkgs.fetchurl {
      url = "https://w.wallhaven.cc/full/8g/wallhaven-8ge2x1.png";
      sha256 = "sha256-tQkP1g9KkOmc6IZgWhok8xuzjd0hu+IKOCp+SM0arQk=";
    };
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
    cursor = {
      package = pkgs.nordzy-cursor-theme;
      name = "Nordzy-cursors";
      size = 32;
    };
  };
}
