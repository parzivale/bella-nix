{
  flake.modules.nixos.sober =
    { config, lib, ... }:
    let
      user = config.systemConstants.username;
    in
    {
      services.flatpak = {
        enable = true;
        packages = [
          "org.vinegarhq.Sober"
        ];
        overrides."org.vinegarhq.Sober".Environment.DRI_PRIME = "1";
      };

      preservation = lib.mkMerge [
        {
          preserveAt."/persistent".directories = [
            {
              directory = "/var/lib/flatpak";
              mode = "0755";
            }
          ];
        }
        (config.helpers.mkPreserve user {
          directories = [
            { directory = ".var/app/org.vinegarhq.Sober/data"; }
          ];
        })
      ];
    };
}
