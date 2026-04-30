{
  moduleWithSystem,
  inputs,
  ...
}: {
  flake.modules.nixos.xdg-desktop-portal-termfilepickers = moduleWithSystem ({inputs', ...}: {
    imports = [
      inputs.xdg-desktop-portal-termfilepickers.nixosModules.default
    ];

    xdg.portal = {
      enable = true;
      extraPortals = [
        inputs'.xdg-desktop-portal-termfilepickers.packages.default
      ];
    };
  });
}
