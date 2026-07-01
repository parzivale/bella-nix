{
  flake.modules.nixos.printing = {
    services.printing = {
      enable = true;
      browsed.enable = false;
      drivers = [ ];
    };
  };
}
