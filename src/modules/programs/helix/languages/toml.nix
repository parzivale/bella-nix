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
          name = "toml";
          auto-format = true;
          language-servers = ["taplo" "harper-ls"];
          formatter = {
            command = "${pkgs.taplo}/bin/taplo";
            args = ["format" "-"];
          };
        }
      ];
      language-server.taplo = {
        command = "${pkgs.taplo}/bin/taplo";
        args = ["lsp" "stdio"];
      };
    };
  };
}
