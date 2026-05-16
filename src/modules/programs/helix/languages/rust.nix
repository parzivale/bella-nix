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
          name = "rust";
          auto-format = true;
          language-servers = ["rust-analyzer" "harper-ls"];
          formatter.command = "${pkgs.rustfmt}/bin/rustfmt";
        }
      ];
      language-server.rust-analyzer = {
        command = "rust-analyzer";
        config = {
          check.command = "clippy";
          cargo.features = "all";
        };
      };
    };
  };
}
