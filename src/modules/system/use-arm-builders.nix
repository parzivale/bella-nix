{self, ...}: {
  flake.modules.nixos.use-arm-builders = {config, ...}: {
    imports = [self.modules.nixos.nix-builder-client];

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
