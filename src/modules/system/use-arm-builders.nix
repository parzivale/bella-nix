{...}: {
  flake.modules.nixos.use-arm-builders = {config, ...}: {
    programs.ssh.knownHosts."macbook".publicKey = builtins.readFile ../../hosts/macbook/ssh_host_ed25519_key.pub;

    nix.distributedBuilds = true;
    nix.buildMachines = [
      {
        hostName = "macbook";
        sshUser = "nix-builder";
        sshKey = config.age.secrets.nix-builder-key.path;
        systems = ["aarch64-linux"];
        maxJobs = 8;
        supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
      }
    ];
  };
}
