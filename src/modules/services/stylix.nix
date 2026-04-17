{inputs, ...}: {
  flake.modules.nixos.stylix = {
    pkgs,
    config,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    imports = [inputs.stylix.nixosModules.default];
    programs.dconf.enable = true;
    home-manager.users.${user} = {
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
          package = pkgs.twitter-color-emoji;
          name = "Twitter Color Emoji";
        };
      };
    };
  };
}
