{
  flake.modules.homeManager.helix = {...}: {
    programs.helix.languages.language = [
      {
        name = "javascript";
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
  };
}
