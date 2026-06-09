{
  flake.modules.homeManager.helix =
    { pkgs, ... }:
    {
      programs.helix.languages = {
        language = [
          {
            name = "toml";
            auto-format = true;
            language-servers = [
              "taplo"
              "harper-ls"
            ];
            formatter = {
              command = "${pkgs.taplo}/bin/taplo";
              args = [
                "format"
                "-"
              ];
            };
          }
        ];
        language-server.taplo = {
          command = "${pkgs.taplo}/bin/taplo";
          args = [
            "lsp"
            "stdio"
          ];
        };
      };
    };
}
