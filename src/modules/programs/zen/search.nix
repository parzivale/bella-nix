{
  flake.modules.nixos.zen = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.programs.zen-browser.profiles.${user}.search = {
      force = true;
      default = "duckduckgo";
      privateDefault = "duckduckgo";
      order = ["Nix Packages" "Nix Options" "Nix Wiki" "Nix Home Manager Options" "Github" "Rust Standard Library" "Rust Libraries" "google" "Google Images"];
      engines = {
        ddg.metaData.alias = "@ddg";
        bing.metaData.hidden = true;
        google.metaData.hidden = true;
        wikipedia.metaData.hidden = true;
        ecosia.metaData.hidden = true;
        perplexity.metaData.hidden = true;
        "Nix Packages" = {
          urls = [{template = "https://search.nixos.org/packages?type=packages&channel=unstable&query={searchTerms}";}];
          icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          definedAliases = ["@np"];
        };
        "NixOS Options" = {
          urls = [{template = "https://search.nixos.org/options?channel=unstable&query={searchTerms}";}];
          icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          definedAliases = ["@no"];
        };
        "NixOS Wiki" = {
          urls = [{template = "https://wiki.nixos.org/w/index.php?search={searchTerms}";}];
          icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          definedAliases = ["@nw"];
        };
        "Home Manager Options" = {
          urls = [{template = "https://home-manager-options.extranix.com/?release=master&query={searchTerms}";}];
          icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          definedAliases = ["@ho"];
        };
        "Github" = {
          urls = [{template = "https://github.com/search?type=repositories&q={searchTerms}";}];
          icon = "https://github.com/favicon.ico";
          definedAliases = ["@gh"];
        };
        "Rust Standard Library" = {
          urls = [{template = "https://doc.rust-lang.org/std/?search={searchTerms}";}];
          icon = "https://rust-lang.org/static/images/favicon.ico";
          definedAliases = ["@std"];
        };
        "Rust Libraries" = {
          urls = [{template = "https://lib.rs/search?q={searchTerms}";}];
          icon = "https://lib.rs/favicon.ico";
          definedAliases = ["@lib"];
        };
        "Google Images" = {
          urls = [{template = "https://google.com/search?udm=2&q={searchTerms}";}];
          icon = "https://google.com/favicon.ico";
          definedAliases = ["@gi"];
        };
        "Youtube" = {
          urls = [{template = "https://youtube.com/results?search_query={searchTerms}";}];
          icon = "https://youtube.com/favicon.ico";
          definedAliases = ["@yt"];
        };
      };
    };
  };
}
