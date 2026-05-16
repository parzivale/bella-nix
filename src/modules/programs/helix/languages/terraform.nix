{
  flake.modules.nixos.helix = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.programs.helix.languages = {
      language = [
        {
          name = "hcl";
          auto-format = true;
          language-servers = ["terraform-ls" "harper-ls"];
          formatter = {
            command = "${pkgs.terraform}/bin/terraform";
            args = ["fmt" "-"];
          };
        }
      ];
      language-server.terraform-ls = {
        command = "${pkgs.terraform-ls}/bin/terraform-ls";
        args = ["serve"];
      };
    };
  };
}
