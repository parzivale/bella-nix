{
  flake.modules.nixos.postgres = {config, ...}: {
    services.postgresql = {
      enable = true;
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
