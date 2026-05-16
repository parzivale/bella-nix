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
          name = "nu";
          auto-format = true;
          language-servers = ["nu-lsp" "harper-ls"];
        }
      ];
      language-server.nu-lsp = {
        command = "${pkgs.nushell}/bin/nu";
        args = ["--lsp"];
      };
    };
  };
}
