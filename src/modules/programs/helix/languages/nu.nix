{
  flake.modules.homeManager.helix =
    { pkgs, ... }:
    {
      programs.helix.languages = {
        language = [
          {
            name = "nu";
            auto-format = true;
            language-servers = [
              "nu-lsp"
              "harper-ls"
            ];
          }
        ];
        language-server.nu-lsp = {
          command = "${pkgs.nushell}/bin/nu";
          args = [ "--lsp" ];
        };
      };
    };
}
