{
  moduleWithSystem,
  inputs,
  ...
}: {
  flake.modules.nixos.zen = moduleWithSystem ({
    pkgs,
    inputs',
    ...
  }: {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.sharedModules = [
      inputs.zen-browser.homeModules.twilight
    ];

    preservation.preserveAt."/persistent".users.${user} = {
      directories = [
        {
          directory = ".config/zen";
        }
      ];
    };

    home-manager.users.${user} = {
      stylix.targets.zen-browser.profileNames = [user];
      programs.zen-browser = {
        enable = true;
        configPath = ".config/zen";
        profiles.${user} = {
          isDefault = true;

          extensions.packages = with inputs'.firefox-addons.packages; [
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
  });
}
