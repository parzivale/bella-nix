{
  flake.modules.nixos.helix = {
    config,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.programs.helix.languages.language = [
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
