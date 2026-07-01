{
  flake.modules.nixos.upower = {
    services.upower = {
      enable = true;
      noPollBatteries = true;
      criticalPowerAction = "PowerOff";
    };
  };
}
