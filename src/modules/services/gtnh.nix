{inputs, ...}: {
  flake.modules.nixos.gtnh = {
    imports = with inputs.gtnh-nix; [nixosModules.gtnh nixosModules."2.8.4"];
    programs.gtnh = {
      enable = true;
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
