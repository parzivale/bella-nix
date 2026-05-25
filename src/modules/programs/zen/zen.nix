{inputs, ...}: {
  flake.modules.homeManager.zen = {
    pkgs,
    osConfig,
    ...
  }: let
    user = osConfig.systemConstants.username;
    system = pkgs.stdenv.hostPlatform.system;
  in {
    programs.zen-browser = {
      enable = true;
      configPath = ".config/zen";
      profiles.${user} = {
        isDefault = true;

        extensions.packages = with inputs.firefox-addons.packages.${system}; [
          ublock-origin
        ];

        settings = {
          "browser.aboutConfig.showWarning" = false;
          "browser.ctrlTab.sortByRecentlyUsed" = true;
          "browser.warnOnQuitShortcut" = false;
          "zen.workspaces.continue-where-left-off" = true;
          "zen.view.show-newtab-button-top" = false;
          "ui.systemUsesDarkTheme" = 1;
          "browser.theme.toolbar-theme" = 0;
          "browser.theme.content-theme" = 0;
          "browser.theme.dark-private-windows" = true;
          "zen.welcome-screen.seen" = true;
        };
      };
    };
  };

  flake.modules.nixos.zen = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.sharedModules = [inputs.zen-browser.homeModules.twilight];

    preservation = config.helpers.mkPreserve user {
      directories = [{directory = ".config/zen";}];
    };

    home-manager.users.${user}.imports = [inputs.self.modules.homeManager.zen];
  };
}
