{ inputs, ... }:
{
  flake.modules.homeManager.modprobed-db =
    { config, pkgs, ... }:
    {
      home.packages = [ pkgs.modprobed-db ];

      # Static, so this stays a nix-store symlink rather than the tool's
      # normal first-run-interactive skeleton copy.
      xdg.configFile."modprobed-db.conf".text = ''
        DBPATH="${config.home.homeDirectory}/.config"
        COLORS=dark
        IGNORE=()
      '';

      # Mirrors the units modprobed-db ships (init/modprobed-db.{service,timer}),
      # just with ExecStart pointed at the nix store instead of /usr/bin.
      systemd.user.services.modprobed-db = {
        Unit = {
          Description = "modprobed-db scan and store new modules";
          Wants = [ "modprobed-db.timer" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.modprobed-db}/bin/modprobed-db storesilent";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };

      systemd.user.timers.modprobed-db = {
        Unit = {
          Description = "Check for new modules";
          PartOf = "modprobed-db.service";
        };
        Timer = {
          OnUnitActiveSec = "6h";
        };
      };
    };

  flake.modules.nixos.modprobed-db =
    { config, ... }:
    let
      user = config.systemConstants.username;
    in
    {
      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.modprobed-db ];

      # The db is the only real state here — the package, config, and units
      # are all reproducible from the store, so only the accumulated module
      # list needs to survive the tmpfs root wipe.
      preservation = config.helpers.mkPreserve user {
        files = [ { file = ".config/modprobed.db"; } ];
      };
    };
}
