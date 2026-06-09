{
  flake.modules.homeManager.helix =
    { pkgs, ... }:
    {
      programs.helix.languages = {
        language = [
          {
            name = "html";
            auto-format = true;
            language-servers = [
              "vscode-html-language-server"
              "harper-ls"
            ];
            formatter = {
              command = "${pkgs.prettier}/bin/prettier";
              args = [
                "--parser"
                "html"
              ];
            };
          }
        ];
        language-server.vscode-html-language-server = {
          command = "${pkgs.vscode-langservers-extracted}/bin/vscode-html-language-server";
          args = [ "--stdio" ];
          config.provideFormatter = true;
        };
      };
    };
}
