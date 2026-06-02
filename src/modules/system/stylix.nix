{inputs, ...}: {
  flake.modules.homeManager.stylix = {osConfig, ...}: let
    user = osConfig.systemConstants.username;
  in {
    stylix.targets.zen-browser.profileNames = [user];
    gtk.gtk4.theme = null;
    xdg.desktopEntries = {
      qt5ct = {
        name = "Qt5 Settings";
        noDisplay = true;
      };
      qt6ct = {
        name = "Qt6 Settings";
        noDisplay = true;
      };
      kvantummanager = {
        name = "Kvantum Manager";
        noDisplay = true;
      };
    };
  };

  flake.modules.nixos.stylix = {
    pkgs,
    config,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    imports = [inputs.stylix.nixosModules.default];
    programs.dconf.enable = true;

    home-manager.users.${user}.imports = [inputs.self.modules.homeManager.stylix];

    stylix = {
      enable = true;
      image = config.systemConstants.bg_img;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
      icons = {
        package = pkgs.papirus-icon-theme;
        dark = "Papirus-Dark";
        enable = true;
      };
      cursor = {
        package = pkgs.nordzy-cursor-theme;
        name = "Nordzy-cursors";
        size = 32;
      };
      fonts = {
        sansSerif = {
          package = pkgs.atkinson-hyperlegible-next;
          name = "Atkinson Hyperlegible Next";
        };
        serif = {
          package = pkgs.atkinson-hyperlegible-next;
          name = "Atkinson Hyperlegible Next";
        };
        monospace = {
          package = pkgs.maple-mono.NF-CN;
          name = "Maple Mono NF CN";
        };
        emoji = {
          package = pkgs.noto-fonts-color-emoji;
          name = "Noto Color Emoji";
        };
        sizes.popups = 14;
      };
    };
  };
}
