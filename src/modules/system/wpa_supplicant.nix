_: {
  # wpa_supplicant as finix's supervised service, which is NetworkManager's wifi backend there.
  # Configuration for it goes here.
  #
  # Interfaces NetworkManager adds over D-Bus are configured by NetworkManager, so
  # `services.wpa_supplicant.settings` and `extraConfig` only reach interfaces named in
  # `services.wpa_supplicant.interfaces` - none, while NetworkManager is the one managing wifi.
  flake.modules.finix.wpa_supplicant =
    { modules, ... }:
    {
      # not part of finix's base system, so the host asks for the module as well as the service
      imports = [ modules.wpa_supplicant ];

      services.wpa_supplicant.enable = true;
    };
}
