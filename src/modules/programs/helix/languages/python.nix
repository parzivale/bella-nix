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
          name = "python";
          auto-format = true;
          language-servers = [
            {
              name = "pyright";
              except-features = ["format"];
            }
            "ruff"
            "harper-ls"
          ];
          formatter = {
            command = "${pkgs.ruff}/bin/ruff";
            args = ["format" "--quiet" "-"];
          };
        }
      ];
      language-server = {
        pyright = {
          command = "${pkgs.pyright}/bin/pyright-langserver";
          args = ["--stdio"];
          config = {};
        };
        ruff = {
          command = "${pkgs.ruff}/bin/ruff";
          args = ["server"];
        };
      };
    };
  };
}
