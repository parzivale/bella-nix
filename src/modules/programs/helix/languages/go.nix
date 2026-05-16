{
  flake.modules.nixos.helix = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.programs.helix.languages = {
      language = [
        {
          name = "go";
          auto-format = true;
          language-servers = ["gopls" "harper-ls"];
        }
      ];
      language-server.gopls.command = "${pkgs.gopls}/bin/gopls";
    };
  };
}
