{
  flake.modules.homeManager.helix = {pkgs, ...}: {
    programs.helix.languages = {
      language = [
        {
          name = "yaml";
          auto-format = true;
          language-servers = ["yaml-language-server" "harper-ls"];
          formatter = {
            command = "${pkgs.prettier}/bin/prettier";
            args = ["--parser" "yaml"];
          };
        }
      ];
      language-server.yaml-language-server = {
        command = "${pkgs.yaml-language-server}/bin/yaml-language-server";
        args = ["--stdio"];
        config.yaml.format.enable = true;
      };
    };
  };
}
