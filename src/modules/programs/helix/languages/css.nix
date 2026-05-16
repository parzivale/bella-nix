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
          name = "css";
          auto-format = true;
          language-servers = ["vscode-css-language-server" "harper-ls"];
          formatter = {
            command = "${pkgs.prettier}/bin/prettier";
            args = ["--parser" "css"];
          };
        }
      ];
      language-server.vscode-css-language-server = {
        command = "${pkgs.vscode-langservers-extracted}/bin/vscode-css-language-server";
        args = ["--stdio"];
        config = {
          provideFormatter = true;
          css.validate.enable = true;
        };
      };
    };
  };
}
