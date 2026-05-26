{inputs, ...}: {
  flake.modules.nixos.gtnh = {config, lib, ...}: {
    imports = [inputs.gtnh-nix.nixosModules."2.8.4"];

    programs.gtnh = {
      enable = true;
      minecraft.instance-options.jvmMaxAllocation = "15G";
      minecraft.server-properties.rcon-port = 25575;
      minecraft.server-properties.max-tick-time = -1;
      minecraft.instance-options.jvmOpts = lib.concatStringsSep " " [
        "-Dfml.readTimeout=180"
        "-Dfile.encoding=UTF-8"
        "-Djava.system.class.loader=com.gtnewhorizons.retrofuturabootstrap.RfbSystemClassLoader"
        "--add-opens java.base/java.io=ALL-UNNAMED"
        "--add-opens java.base/java.lang.invoke=ALL-UNNAMED"
        "--add-opens java.base/java.lang.ref=ALL-UNNAMED"
        "--add-opens java.base/java.lang.reflect=ALL-UNNAMED"
        "--add-opens java.base/java.lang=ALL-UNNAMED"
        "--add-opens java.base/java.net.spi=ALL-UNNAMED"
        "--add-opens java.base/java.net=ALL-UNNAMED"
        "--add-opens java.base/java.nio.channels=ALL-UNNAMED"
        "--add-opens java.base/java.nio.charset=ALL-UNNAMED"
        "--add-opens java.base/java.nio.file=ALL-UNNAMED"
        "--add-opens java.base/java.nio=ALL-UNNAMED"
        "--add-opens java.base/java.text=ALL-UNNAMED"
        "--add-opens java.base/java.time.chrono=ALL-UNNAMED"
        "--add-opens java.base/java.time.format=ALL-UNNAMED"
        "--add-opens java.base/java.time.temporal=ALL-UNNAMED"
        "--add-opens java.base/java.time.zone=ALL-UNNAMED"
        "--add-opens java.base/java.time=ALL-UNNAMED"
        "--add-opens java.base/java.util.concurrent.atomic=ALL-UNNAMED"
        "--add-opens java.base/java.util.concurrent.locks=ALL-UNNAMED"
        "--add-opens java.base/java.util.jar=ALL-UNNAMED"
        "--add-opens java.base/java.util.zip=ALL-UNNAMED"
        "--add-opens java.base/java.util=ALL-UNNAMED"
        "--add-opens java.base/jdk.internal.loader=ALL-UNNAMED"
        "--add-opens java.base/jdk.internal.misc=ALL-UNNAMED"
        "--add-opens java.base/jdk.internal.ref=ALL-UNNAMED"
        "--add-opens java.base/jdk.internal.reflect=ALL-UNNAMED"
        "--add-opens java.base/sun.nio.ch=ALL-UNNAMED"
        "--add-opens java.desktop/com.sun.imageio.plugins.png=ALL-UNNAMED"
        "--add-opens java.desktop/sun.awt.image=ALL-UNNAMED"
        "--add-opens java.desktop/sun.awt=ALL-UNNAMED"
        "--add-opens java.sql.rowset/javax.sql.rowset.serial=ALL-UNNAMED"
        "--add-opens jdk.dynalink/jdk.dynalink.beans=ALL-UNNAMED"
        "--add-opens jdk.naming.dns/com.sun.jndi.dns=ALL-UNNAMED,java.naming"
        "-Dfml.queryResult=confirm"
      ];
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
