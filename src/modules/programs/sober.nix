{ inputs, ... }:
{
  flake.modules.nixos.sober =
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

      services.flatpak = {
        enable = true;
        packages = [
          "org.vinegarhq.Sober"
        ];
        overrides."org.vinegarhq.Sober".Environment.DRI_PRIME = "1";
      };

      state.preserve = {
        directories = [
          {
            directory = "/var/lib/flatpak";
            mode = "0755";
          }
        ];

        users.${user}.directories = [
          { directory = ".var/app/org.vinegarhq.Sober/data"; }
        ];
      };
    };
}
