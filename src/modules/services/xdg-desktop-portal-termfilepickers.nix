{
  moduleWithSystem,
  inputs,
  ...
}: {
  flake.modules.nixos.xdg-desktop-portal-termfilepickers = moduleWithSystem ({inputs', ...}: {pkgs, ...}: {
    imports = [
      inputs.xdg-desktop-portal-termfilepickers.nixosModules.default
    ];

    services.xdg-desktop-portal-termfilepickers = {
      enable = true;
      package = inputs'.xdg-desktop-portal-termfilepickers.packages.default;
      config.terminal_command = ["${pkgs.wezterm}/bin/wezterm" "start" "--always-new-process" "--"];
    };

    xdg.portal = {
      enable = true;
      config.common.default = ["gnome"];
    };
  });
}
