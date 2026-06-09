{
  flake.modules.homeManager.helix = _: {
    programs.helix.languages.language = [
      {
        name = "jsx";
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
