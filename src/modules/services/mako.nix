{ inputs, ... }:
let
  settings = {
    default-timeout = 5000;
    border-radius = 8;
    margin = "10";
    padding = "12";
    icon-path = "/run/current-system/sw/share/icons/Papirus-Dark";
  };
in
{
  flake.modules.homeManager.mako = _: {
    services.mako = {
      enable = true;
      inherit settings;
    };
  };

  flake.modules.nixos.mako =
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      imports = [ inputs.self.modules.nixos.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.mako ];
    };

  flake.modules.finix.mako =
    {
      config,
      pkgs,
      ...
    }:
    let
      user = config.constants.username;
    in
    {
      imports = [ inputs.self.modules.finix.home-manager ];

      # home-manager's mako module writes the configuration file and a user
      # service. The file is what is wanted from it; the service is inert here, so
      # the daemon is started through `state.startup` instead.
      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.mako ];

      state.startup = [ [ "${pkgs.mako}/bin/mako" ] ];
    };
}
