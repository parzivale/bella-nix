{inputs, ...}: {
  flake.modules.nixos.stylix = {
    pkgs,
    config,
    ...
  }: {
    imports = [inputs.stylix.nixosModules.default];
    stylix = {
      enable = true;
      image = config.systemConstants.bg_img;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";
      cursor = {
        package = pkgs.nordzy-cursor-theme;
        name = "Nordzy-cursors";
        size = 32;
      };
    };
  };
}
