{
  flake.modules.nixos.postgres = {
    config,
    lib,
    pkgs,
    ...
  }: {
    age.secrets.cloudflare-buckets.rekeyFile = ../../secrets/cloudflare-buckets/access_env.age;
    age.secrets.restic-postgres-password.rekeyFile = ../../secrets/restic/postgres-password.age;

    services.postgresql = {
      enable = true;
    };

    services.restic.backups.postgres-backup = {
      initialize = true;
      repository = "s3:https://36a395a8d1dada79c1fc9d8552de08d0.r2.cloudflarestorage.com/postgres-backups";
      environmentFile = config.age.secrets.cloudflare-buckets.path;
      passwordFile = config.age.secrets.restic-postgres-password.path;
      paths = ["/tmp/postgres-backup"];
      backupPrepareCommand = ''
        mkdir -p /tmp/postgres-backup
        ${lib.getExe' pkgs.util-linux "runuser"} -u postgres -- ${lib.getExe' config.services.postgresql.package "pg_dumpall"} > /tmp/postgres-backup/all.sql
      '';
      backupCleanupCommand = "rm -rf /tmp/postgres-backup";
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 3"
      ];
    };
    preservation.preserveAt."/persistent".directories = [
      {
        directory = "/var/lib/postgresql";
        user = "postgres";
        group = "postgres";
        mode = "0750";
      }
    ];
  };
}
