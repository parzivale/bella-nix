{
  flake.modules.homeManager.helix =
    { pkgs, ... }:
    {
      programs.helix.languages = {
        language = [
          {
            name = "hcl";
            auto-format = true;
            language-servers = [
              "terraform-ls"
              "harper-ls"
            ];
            formatter = {
              command = "${pkgs.terraform}/bin/terraform";
              args = [
                "fmt"
                "-"
              ];
            };
          }
        ];
        language-server.terraform-ls = {
          command = "${pkgs.terraform-ls}/bin/terraform-ls";
          args = [ "serve" ];
        };
      };
    };
}
