{...}: {
  flake.modules.nixos.use-arm-builders = {config, ...}: {
    programs.ssh.knownHosts."macbook".publicKey = builtins.readFile ../../hosts/macbook/ssh_host_ed25519_key.pub;

    age.secrets.nix-builder-key.rekeyFile = ../../secrets/nix-builder/nix-builder-key.age;

    nix.distributedBuilds = true;
    nix.buildMachines = [
      {
        protocol = "ssh-ng";
        hostName = "macbook";
        sshUser = "nix-builder";
        sshKey = config.age.secrets.nix-builder-key.path;
        systems = ["aarch64-linux"];
        maxJobs = 8;
        speedFactor = 100;
        supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
      }
    ];
  };
}
