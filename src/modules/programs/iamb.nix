{inputs, ...}: {
  flake.modules.nixos.iamb = {config, pkgs, ...}: let
    user = config.systemConstants.username;
    domain = config.systemConstants.domain;
  in {
    home-manager.users.${user} = {
      xdg.dataFile."applications/iamb.desktop".source = "${inputs.iamb}/iamb.desktop";
      xdg.dataFile."icons/hicolor/scalable/apps/iamb.svg".source = "${inputs.iamb}/docs/iamb.svg";

      programs.iamb = {
        enable = true;
        package = inputs.iamb.packages.${pkgs.stdenv.hostPlatform.system}.default;
        settings = {
          settings = {
            image_preview.protocol.type = "kitty";
            username_display = "displayname";
            notifications.enabled = true;
            sort.rooms = ["favorite" "lowpriority" "unread" "recent"];
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

    preservation.preserveAt."/persistent".users.${user} = {
      directories = [".local/share/iamb"];
    };
  };
}
