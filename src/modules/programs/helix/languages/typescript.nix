{
  flake.modules.homeManager.helix = {pkgs, ...}: {
    programs.helix.languages = {
      language = [
        {
          name = "typescript";
          auto-format = true;
          language-servers = [
            {
              name = "typescript-language-server";
              except-features = ["format"];
            }
            "biome"
            "harper-ls"
          ];
        }
      ];
      language-server = {
        typescript-language-server = {
          command = "${pkgs.typescript-language-server}/bin/typescript-language-server";
          args = ["--stdio"];
          config.hostInfo = "helix";
        };
        biome = {
          command = "${pkgs.biome}/bin/biome";
          args = ["lsp-proxy"];
        };
      };
    };
  };
}
