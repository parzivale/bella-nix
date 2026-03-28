{self, ...}: {
  flake.modules.nixos.use-x86-builders = {config, ...}: {
    imports = [self.modules.nixos.nix-builder-client];

    nix.buildMachines = [
      {
        hostName = "hp-victus-laptop";
        sshUser = "nix-builder";
        sshKey = config.age.secrets.nix-builder-key.path;
        systems = ["x86_64-linux"];
        supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
      }
    ];
  };
}
