{
  moduleWithSystem,
  inputs,
  ...
}:
let
  terminal = pkgs: [
    "${pkgs.wezterm}/bin/wezterm"
    "start"
    "--always-new-process"
    "--"
  ];
in
{
  flake.modules.nixos.xdg-desktop-portal-termfilepickers = moduleWithSystem (
    { inputs', ... }:
    { pkgs, ... }:
    {
      imports = [
        inputs.xdg-desktop-portal-termfilepickers.nixosModules.default
      ];

      services.xdg-desktop-portal-termfilepickers = {
        enable = true;
        package = inputs'.xdg-desktop-portal-termfilepickers.packages.default;
        config.terminal_command = terminal pkgs;
      };

      xdg.portal = {
        enable = true;
        config.common.default = [ "gtk" ];
      };
    }
  );

  # The upstream module is not imported: its whole body is one
  # `systemd.user.services` unit plus the two portal settings below, and the unit
  # is the part that does not carry over.
  #
  # A portal is normally D-Bus activated, which would have made this a matter of
  # installing the package - but this one ships only its `.portal` file, naming
  # `org.freedesktop.impl.portal.desktop.termfilepickers`, and no D-Bus service
  # file to activate that name. So something has to start the process.
  flake.modules.finix.xdg-desktop-portal-termfilepickers = moduleWithSystem (
    { inputs', ... }:
    { pkgs, ... }:
    let
      package = inputs'.xdg-desktop-portal-termfilepickers.packages.default;

      config = (pkgs.formats.toml { }).generate "termfilepickers.toml" {
        terminal_command = terminal pkgs;
      };
    in
    {
      imports = [ inputs.self.modules.finix.graphical-session ];

      xdg.portal = {
        enable = true;
        portals = [ package ];
        config.common = {
          default = [ "gtk" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "termfilepickers" ];
        };
      };

      state.session.services.xdg-desktop-portal-termfilepickers = {
        description = "terminal file chooser portal";
        # `--config-path` is what the upstream unit passes, and the file is written
        # here for the same reason the command is: there is no module left to do
        # either.
        command = [
          "${package}/bin/xdg-desktop-portal-termfilepickers"
          "--config-path"
          "${config}"
        ];
      };
    }
  );
}
