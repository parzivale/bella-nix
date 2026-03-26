{inputs, ...}: {
  flake.modules.nixos.fabric = {pkgs, ...}: {
    imports = [inputs.nix-minecraft.nixosModules.minecraft-servers];

    services.minecraft-servers = {
      enable = true;
      eula = true;

      servers.fabric = {
        enable = true;
        package = pkgs.fabricServers.fabric-1_21_4;
        jvmOpts = "-Xms4G -Xmx8G";

        serverProperties = {
          server-port = 25565;
          difficulty = "normal";
          gamemode = "survival";
          max-players = 10;
          motd = "Bella's Fabric Server";
        };

        symlinks = {
          mods = pkgs.linkFarmFromDrvs "mods" (builtins.attrValues {
            FabricAPI = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/p96k10UR/fabric-api-0.119.4%2B1.21.4.jar";
              hash = "sha256-0YO6y4RRZ/CSZML5AyK37P/ogm3r2m9g5ZeIkmS+9K8=";
            };
            Geyser = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/wKkoqHrH/versions/6CGF7CTR/geyser-fabric-Geyser-Fabric-2.6.2-b796.jar";
              hash = "sha256-tmYPmmGYKKvQ/ENFg/53ZF6rrqmpHPzJFPOMQr5uRgA=";
            };
          });
        };
      };
    };

    networking.firewall = {
      allowedTCPPorts = [25565];
      allowedUDPPorts = [19132];
    };

    preservation = {
      preserveAt."/persistent".directories = ["/srv/minecraft"];
    };
  };
}
