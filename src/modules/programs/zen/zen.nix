{ inputs, ... }:
let
  # One body for both classes: the only thing that differed was
  # `home-manager.sharedModules`, which the community module has no equivalent
  # for - and with a single user there was nothing to share it with anyway, so
  # the browser's own module is named in this user's imports on both.
  zen =
    homeManager:
    { config, ... }:
    let
      user = config.systemConstants.username;
    in
    {
      imports = [ homeManager ];

      home-manager.users.${user}.imports = [
        inputs.zen-browser.homeModules.twilight
        inputs.self.modules.homeManager.zen
      ];

      state.preserve.users.${user} = {
        directories = [ { directory = ".config/zen"; } ];
      };
    };
in
{
  flake.modules.homeManager.zen =
    {
      pkgs,
      osConfig,
      ...
    }:
    let
      user = osConfig.systemConstants.username;
      system = pkgs.stdenv.hostPlatform.system;
    in
    {
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

  flake.modules.nixos.zen = zen inputs.self.modules.nixos.home-manager;
  flake.modules.finix.zen = zen inputs.self.modules.finix.home-manager;
}
