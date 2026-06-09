{
  flake.modules.homeManager.helix =
    { pkgs, ... }:
    {
      programs.helix.languages = {
        language = [
          {
            name = "markdown";
            auto-format = true;
            soft-wrap.enable = true;
            soft-wrap.wrap-at-text-width = true;
            text-width = 80;
            language-servers = [
              "marksman"
              "harper-ls"
            ];
            formatter = {
              command = "${pkgs.prettier}/bin/prettier";
              args = [
                "--parser"
                "markdown"
              ];
            };
          }
        ];
        language-server.marksman = {
          command = "${pkgs.marksman}/bin/marksman";
          args = [ "server" ];
        };
      };
    };
}
