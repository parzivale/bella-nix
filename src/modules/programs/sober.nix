{
  flake.modules.nixos.sober = {
    services.flatpak = {
      enable = true;
      packages = [
        "org.vinegarhq.Sober"
      ];
    };
  };
}
