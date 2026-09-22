{
  flake.modules.homeManager.helix =
    { pkgs, ... }:
    {
      programs.helix.languages = {
        language = [
          {
            name = "c-sharp";
            auto-format = true;
            language-servers = [
              "csharp-ls"
              "harper-ls"
            ];
            formatter = {
              command = "${pkgs.csharpier}/bin/csharpier";
              args = [
                "format"
                "--write-stdout"
              ];
            };
          }
        ];
        language-server.csharp-ls = {
          command = "${pkgs.csharp-ls}/bin/csharp-ls";
          config = { };
        };
      };
    };
}
