{
  flake.modules.nixos.hibernation = {
    # Suspend then hibernate after 20 minutes of suspend
    systemd.sleep.settings.Sleep.HibernateDelaySec = "20min";

    services.logind = {
      settings.Login = {
        HandleLidSwitchExternalPower = "hibernate";
        HandleLidSwitch = "hibernate";
        IdleAction = "sleep";
        IdleActionSec = "5min";
      };
    };

    boot.kernelParams = ["mem_sleep_default=deep"];

    powerManagement.enable = true;
  };
}
