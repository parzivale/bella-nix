{
  flake.modules.nixos.helix = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.programs.helix.languages.language-server.harper-ls = {
      command = "${pkgs.harper}/bin/harper-ls";
      args = ["--stdio"];
      config.harper-ls.linters.SpellCheck = true;
    };
  };
}
