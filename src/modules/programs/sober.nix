{
  flake.modules.nixos.sober = {config, ...}: let
    user = config.systemConstants.username;
  in {
    services.flatpak = {
      enable = true;
      packages = [
        "org.vinegarhq.Sober"
      ];
      overrides."org.vinegarhq.Sober".Environment.DRI_PRIME = "1";
    };

    preservation.preserveAt."/persistent" = {
      directories = [
        {
          directory = "/var/lib/flatpak";
          mode = "0755";
        }
      ];
      users.${user}.directories = [
        {directory = ".var/app/org.vinegarhq.Sober/data";}
      ];
    };
  };
}
