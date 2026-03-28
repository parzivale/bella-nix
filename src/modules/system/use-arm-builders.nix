{...}: {
  flake.modules.nixos.use-arm-builders = {config, ...}: {
    nix.distributedBuilds = true;
    nix.buildMachines = [
      {
        hostName = "macbook";
        sshUser = "nix-builder";
        sshKey = config.age.secrets.nix-builder-key.path;
        systems = ["aarch64-linux"];
        supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
      }
    ];
  };
}
