{inputs, ...}: {
  flake.modules.nixos.gtnh = {config, ...}: {
    imports = [inputs.gtnh-nix.nixosModules."2.8.4"];

    programs.gtnh = {
      enable = true;
      minecraft.instance-options.jvmMaxAllocation = "15G";
      minecraft.server-properties.rcon-port = 25575;
      minecraft.server-properties.max-tick-time = -1;
    };

    age.secrets.cloudflare-buckets.rekeyFile = ../../secrets/cloudflare-buckets/access_env.age;

    services.restic.backups.gtnh-backup = {
      initialize = true;
      repository = "https://36a395a8d1dada79c1fc9d8552de08d0.r2.cloudflarestorage.com/gtnh-backups";
      environmentFile = config.age.secrets.cloudflare-buckets.path;
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
