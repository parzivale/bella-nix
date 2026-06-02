{inputs, ...}: {
  flake.modules.nixos.gtnh = {
    config,
    lib,
    ...
  }: {
    imports = [inputs.gtnh-nix.nixosModules."2.8.4"];

    programs.gtnh = {
      enable = true;
      mods.GregTech.Pollution_cfg.pollution."Activate Pollution" = false;
      minecraft = {
        server-properties = {
          rcon-port = 25575;
          max-tick-time = -1;
        };
        instance-options = {
          jvmMaxAllocation = "15G";
          extraJvmOpts = ["-Dfml.queryResult=confirm"];
        };
      };
    };
    age.secrets.cloudflare-buckets.rekeyFile = ../../secrets/cloudflare-buckets/access_env.age;
    age.secrets.restic-gtnh-password.rekeyFile = ../../secrets/restic/gtnh-password.age;

    services.restic.backups.gtnh-backup = {
      initialize = true;
      repository = "s3:https://36a395a8d1dada79c1fc9d8552de08d0.r2.cloudflarestorage.com/gtnh-backups";
      environmentFile = config.age.secrets.cloudflare-buckets.path;
      passwordFile = config.age.secrets.restic-gtnh-password.path;
      paths = ["/var/lib/gtnh"];
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 3"
      ];
    };

    preservation.preserveAt."/persistent".directories = ["/var/lib/gtnh"];
  };
}
