{inputs, ...}: {
  flake.modules.nixos.gtnh = {config, ...}: {
    imports = with inputs.gtnh-nix; [nixosModules.gtnh nixosModules."2.8.4"];
    services.restic.backups.gtnh-backup = {
      initalize = true;
      repositry = "https://36a395a8d1dada79c1fc9d8552de08d0.r2.cloudflarestorage.com/gtnh-backups";
      environmentFile = config.age.secrets.cloudflare-buckets.path;
      paths = ["/var/lib/gtnh"];
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 3"
      ];
    };
    programs.gtnh = {
      enable = true;
      mods = {
        GregTech.Pollution.pollution."Activate Pollution" = false;
      };
      minecraft = {
        instance-options = {
          jvmMaxAllocation = "15G";
          jvmInitialAllocation = "6G";
        };
        server-properties = {
          max-tick-time = -1;
        };
      };
    };
    preservation = {
      preserveAt."/persistent".directories = ["/var/lib/gtnh"];
    };
  };
}
