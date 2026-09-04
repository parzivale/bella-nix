{ inputs, ... }:
{
  flake.modules.nixos.atm10 =
    {
      config,
      pkgs,
      ...
    }:
    let
      atm10ServerFiles = pkgs.stdenvNoCC.mkDerivation {
        pname = "atm10-server-files";
        version = "8.1";
        src = pkgs.fetchurl {
          url = "https://mediafilez.forgecdn.net/files/8764/245/ServerFiles-8.1.zip";
          hash = "sha256-JZ5KmIiO5t7QtDkRPBmsPHn26Q7qsaLEZaHABdDV88Q=";
        };
        nativeBuildInputs = [ pkgs.unzip ];
        dontUnpack = true;
        installPhase = ''
          mkdir -p $out
          unzip -q $src -d $out
        '';
      };
    in
    {
      imports = [ inputs.nix-minecraft.nixosModules.minecraft-servers ];

      services.minecraft-servers = {
        enable = true;
        eula = true;

        servers.atm10 = {
          enable = true;
          # ATM10 requires Java 21; nixpkgs' generic jre_headless (the
          # neoforge-servers package's default) has since moved to a newer
          # major version that FML/Mixin's bytecode transforms silently choke on.
          package = pkgs.neoforgeServers.neoforge-1_21_1-21_1_249.override {
            jre_headless = pkgs.jdk21_headless;
          };

          whitelist = {
            zeus_oliver = "b56d8d37-8dd1-46bc-97c8-8afcb6fe9877";
          };
          operators = {
            zeus_oliver = "b56d8d37-8dd1-46bc-97c8-8afcb6fe9877";
          };

          jvmOpts = "-Xms12G -Xmx12G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1";

          serverProperties = {
            white-list = true;
            server-port = config.systemConstants.ports.minecraft.atm10;
            difficulty = "normal";
            gamemode = "survival";
            max-players = 10;
            motd = "Bella's ATM10 Server";
            allow-flight = true;
            max-tick-time = 180000;
            simulation-distance = 5;
            view-distance = 8;
          };

          # Static modpack content, never written to at runtime.
          symlinks = {
            defaultconfigs = "${atm10ServerFiles}/defaultconfigs";
            datapacks = "${atm10ServerFiles}/datapacks";
          };

          # Mods rewrite these at runtime, so they need to be writable; reset
          # to the modpack's shipped versions on every restart. mods/ also
          # needs to be writable, not just symlinked read-only into the Nix
          # store: crash_assistant's JarJar-nested mixin config fails to load
          # ("invalid or could not be read") when mods/ isn't a real,
          # writable directory (confirmed by reproducing outside of Nix).
          files = {
            mods = "${atm10ServerFiles}/mods";
            config = "${atm10ServerFiles}/config";
            kubejs = "${atm10ServerFiles}/kubejs";
            local = "${atm10ServerFiles}/local";
          };
        };
      };

      networking.firewall.allowedTCPPorts = [ config.systemConstants.ports.minecraft.atm10 ];

      age.secrets.cloudflare-buckets.rekeyFile = ../../secrets/master/cloudflare-buckets/access_env.age;
      age.secrets.restic-atm10-password.rekeyFile = ../../secrets/master/restic/atm10-password.age;

      services.restic.backups.atm10-backup = {
        initialize = true;
        repository = "s3:https://36a395a8d1dada79c1fc9d8552de08d0.r2.cloudflarestorage.com/atm10-backups";
        environmentFile = config.age.secrets.cloudflare-buckets.path;
        passwordFile = config.age.secrets.restic-atm10-password.path;
        paths = [ "/srv/minecraft/atm10/world" ];
        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 4"
          "--keep-monthly 3"
        ];
      };

      # The whole /srv/minecraft tree is one preservation mount shared by
      # every nix-minecraft server on this host; declaring a nested mount at
      # /srv/minecraft/atm10 conflicts with it (can't unmount a parent while
      # a child mount is nested inside it).
      preservation.preserveAt."/persistent".directories = [ "/srv/minecraft" ];
    };
}
