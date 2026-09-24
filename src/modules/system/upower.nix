{ inputs, ... }:
let
  # What upower actually reads. Both classes write this same set - nixos through
  # a named option per key, finix through a freeform `settings` in the file's
  # own vocabulary.
  #
  # The whole set rather than just the two that differ from upower's defaults:
  # this file replaces the one upower ships, so an omitted key falls back to a
  # compiled-in default rather than to the shipped value. Those are believed to
  # agree, and the battery thresholds are not worth resting on a belief.
  settings = {
    EnableWattsUpPro = false;
    NoPollBatteries = true;
    IgnoreLid = false;
    UsePercentageForPolicy = true;
    PercentageLow = 20;
    PercentageCritical = 5;
    PercentageAction = 2;
    TimeLow = 1200;
    TimeCritical = 300;
    TimeAction = 120;
    AllowRiskyCriticalPowerAction = false;
    CriticalPowerAction = "PowerOff";
  };
in
{
  flake.modules.nixos.upower = {
    services.upower = {
      enable = true;
      noPollBatteries = settings.NoPollBatteries;
      criticalPowerAction = settings.CriticalPowerAction;
    };
  };

  flake.modules.finix.upower =
    { modules, ... }:
    {
      imports = [
        modules.upower
        # finix leaves device management off; this module's rules go nowhere
        # without it. No nixos counterpart - see `udev`.
        inputs.self.modules.finix.udev
      ];

      services.upower = {
        enable = true;
        settings.UPower = settings;
      };
    };
}
