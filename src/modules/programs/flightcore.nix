{ inputs, ... }:
{
  flake.modules.homeManager.flightcore =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.flightcore ];
    };

  flake.modules.nixos.flightcore =
    { config, ... }:
    let
      user = config.systemConstants.username;
    in
    {
      imports = [ inputs.self.modules.nixos.home-manager ];

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
}
