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
          name = "json";
          auto-format = true;
          language-servers = ["vscode-json-language-server" "harper-ls"];
          formatter = {
            command = "${pkgs.prettier}/bin/prettier";
            args = ["--parser" "json"];
          };
        }
      ];
      language-server.vscode-json-language-server = {
        command = "${pkgs.vscode-langservers-extracted}/bin/vscode-json-language-server";
        args = ["--stdio"];
        config.provideFormatter = true;
      };
    };
  };
}
