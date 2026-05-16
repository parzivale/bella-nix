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
          name = "html";
          auto-format = true;
          language-servers = ["vscode-html-language-server" "harper-ls"];
          formatter = {
            command = "${pkgs.prettier}/bin/prettier";
            args = ["--parser" "html"];
          };
        }
      ];
      language-server.vscode-html-language-server = {
        command = "${pkgs.vscode-langservers-extracted}/bin/vscode-html-language-server";
        args = ["--stdio"];
        config.provideFormatter = true;
      };
    };
  };
}
