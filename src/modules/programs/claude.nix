{inputs, ...}: {
  flake.modules.homeManager.claude = _: {
    programs.claude-code.enable = true;
  };

  flake.modules.nixos.claude = {config, ...}: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.imports = [inputs.self.modules.homeManager.claude];

    preservation = config.helpers.mkPreserve user {
      directories = [{directory = ".claude"; mode = "0755";}];
      files = [{file = ".claude.json";}];
    };
  };
}
