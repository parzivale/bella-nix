{ inputs, ... }:
{
  flake.modules.homeManager.iamb =
    {
      pkgs,
      osConfig,
      ...
    }:
    let
      domain = osConfig.systemConstants.domain;
      user = osConfig.systemConstants.username;
    in
    {
      xdg.dataFile."applications/iamb.desktop".source = "${pkgs.iamb}/share/applications/iamb.desktop";
      xdg.dataFile."icons/hicolor/scalable/apps/iamb.svg".source =
        "${pkgs.iamb}/share/icons/hicolor/scalable/apps/iamb.svg";

      programs.iamb = {
        enable = true;
        package = pkgs.iamb;
        settings = {
          settings = {
            image_preview = {
              protocol = {
                type = "iterm2";
                font_size = [
                  19
                  43
                ];
              };
              size = {
                width = 60;
                height = 20;
              };
            };
            username_display = "displayname";
            notifications.enabled = true;
            sort.rooms = [
              "favorite"
              "lowpriority"
              "unread"
              "recent"
            ];
          };
          macros."normal|visual" = {
            "<A-W>h" = "<C-W>h";
            "<A-W>j" = "<C-W>j";
            "<A-W>k" = "<C-W>k";
            "<A-W>l" = "<C-W>l";
            "<A-W>H" = "<C-W>H";
            "<A-W>J" = "<C-W>J";
            "<A-W>K" = "<C-W>K";
            "<A-W>L" = "<C-W>L";
            "<A-W>s" = "<C-W>s";
            "<A-W>v" = "<C-W>v";
            "<A-W>q" = "<C-W>q";
            "<A-W>o" = "<C-W>o";
            "<A-W>w" = "<C-W>w";
            "<A-W>W" = "<C-W>W";
            "<A-W>=" = "<C-W>=";
            "<A-W>m" = "<C-W>m";
            "<A-W>z" = "<C-W>z";
          };
          profiles.default = {
            user_id = "@bella:${domain}";
            url = "https://matrix.${domain}";
          };
        };
      };
    };

  flake.modules.nixos.iamb =
    { config, ... }:
    let
      user = config.systemConstants.username;
    in
    {
      imports = [ inputs.self.modules.nixos.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.iamb ];

      state.preserve.users.${user} = {
        directories = [ ".local/share/iamb" ];
      };
    };
}
