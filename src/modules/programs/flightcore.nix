{ inputs, ... }:
let
  # The same module for nixos and finix; `class` only picks which home-manager it imports.
  module =
    class:
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      imports = [ inputs.self.modules.${class}.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.flightcore ];

      # Only persisted state is the tauri store (flight-core-settings.json), which
      # lives in app_config_dir keyed by the bundle identifier. Northstar and mods
      # install into <Titanfall2>/R2Northstar/, under the Steam library that
      # steam.nix already preserves via .local/share/Steam.
      state.preserve.users.${user} = {
        directories = [
          {
            directory = ".config/com.github.r2northstartools.flightcore";
            mode = "0755";
          }
        ];
      };
    };
in
{
  flake.modules.homeManager.flightcore =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.flightcore ];
    };

  flake.modules.nixos.flightcore = module "nixos";
  flake.modules.finix.flightcore = module "finix";
}
