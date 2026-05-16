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
          name = "markdown";
          auto-format = true;
          soft-wrap.enable = true;
          soft-wrap.wrap-at-text-width = true;
          text-width = 80;
          language-servers = ["marksman" "harper-ls"];
          formatter = {
            command = "${pkgs.prettier}/bin/prettier";
            args = ["--parser" "markdown"];
          };
        }
      ];
      language-server.marksman = {
        command = "${pkgs.marksman}/bin/marksman";
        args = ["server"];
      };
    };
  };
}
