{inputs, ...}: {
  flake.modules.nixos.zen = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    home-manager.sharedModules = [
      inputs.zen-browser.homeModules.twilight
    ];
    home-manager.users.${user} = {
      programs.zen-browser = {
        enable = true;
        configPath = ".config/zen";
        profiles."*" = {
          extensions.packages = with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
            ublock-origin
          ];

          settings = {
            "browser.aboutConfig.showWarning" = false;
            "browser.ctrlTab.sortByRecentlyUsed" = true;
            "browser.warnOnQuitShortcut" = false;
            "zen.welcome-screen.seen" = true;
            "zen.workspaces.continue-where-left-off" = true;
            "zen.view.show-newtab-button-top" = false;
          };
          search = {
            default = "ddg";
            privateDefault = "ddg";
            order = ["Nix Packages" "Nix Options" "Nix Wiki" "Nix Home Manager Options" "Github" "Rust Standard Library" "Rust Libraries" "google" "Google Images"];
            engines = {
              google.metaData.alias = "!g";
              bing.metaData.hidden = true;
              ddg.metaData.hidden = true;
              wikipedia.metaData.hidden = true;
              ecosia.metaData.hidden = true;
              perplexity.metaData.hidden = true;
              "Nix Packages" = {
                urls = [{template = "https://search.nixos.org/packages?type=packages&channel=unstable&query={searchTerms}";}];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = ["!np"];
              };
              "NixOS Options" = {
                urls = [{template = "https://search.nixos.org/options?channel=unstable&query={searchTerms}";}];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = ["!no"];
              };
              "NixOS Wiki" = {
                urls = [{template = "https://wiki.nixos.org/w/index.php?search={searchTerms}";}];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = ["!nw"];
              };
              "Home Manager Options" = {
                urls = [{template = "https://home-manager-options.extranix.com/?release=master&query={searchTerms}";}];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = ["!ho"];
              };
              "Arch Linux Wiki" = {
                urls = [{template = "https://wiki.archlinux.org/index.php?search={searchTerms}";}];
                icon = "https://wiki.archlinux.org/favicon.ico";
                definedAliases = ["!aw"];
              };
              "Github" = {
                urls = [{template = "https://github.com/search?type=repositories&q={searchTerms}";}];
                icon = "https://github.com/favicon.ico";
                definedAliases = ["!gh"];
              };
              "Minecraft Wiki" = {
                urls = [{template = "https://minecraft.wiki/?search={searchTerms}";}];
                icon = "https://minecraft.wiki/favicon.ico";
                definedAliases = ["!mc"];
              };
              "Rust Standard Library" = {
                urls = [{template = "https://doc.rust-lang.org/std/?search={searchTerms}";}];
                icon = "https://rust-lang.org/static/images/favicon.ico";
                definedAliases = ["!std"];
              };
              "Rust Libraries" = {
                urls = [{template = "https://lib.rs/search?q={searchTerms}";}];
                icon = "https://lib.rs/favicon.ico";
                definedAliases = ["!lib"];
              };
              "Google Images" = {
                urls = [{template = "https://google.com/search?udm=2&q={searchTerms}";}];
                icon = "https://google.com/favicon.ico";
                definedAliases = ["!gi"];
              };
              "Youtube" = {
                urls = [{template = "https://youtube.com/results?search_query={searchTerms}";}];
                icon = "https://youtube.com/favicon.ico";
                definedAliases = ["!yt"];
              };
              "SoundCloud" = {
                urls = [{template = "https://soundcloud.com/search?q={searchTerms}";}];
                icon = "https://soundcloud.com/favicon.ico";
                definedAliases = ["!sc"];
              };
            };
          };
        };

        policies = {
          DisableTelemetry = true;
          DisableFirefoxStudies = true;
          EnableTrackingProtection = {
            Value = true;
            Locked = true;
            Cryptomining = true;
            Fingerprinting = true;
          };
          DisableAppUpdate = true;
          DisableFeedbackCommands = true;
          DisablePocket = true;
          DisableFirefoxAccounts = true;
          DisableAccounts = true;
          DisableFirefoxScreenshots = true;
          OverrideFirstRunPage = "";
          OverridePostUpdatePage = "";
          DontCheckDefaultBrowser = true;
          DisplayBookmarksToolbar = "never"; # alternatives: "always" or "newtab"
          DisplayMenuBar = "default-off"; # alternatives: "always", "never" or "default-on"
          SearchBar = "unified";
        };
      };
    };
  };
}
