{...}: {
  flake.modules.nixos.use-x86-builders = {config, ...}: {
    programs.ssh.knownHosts."hp-victus-laptop".publicKey = builtins.readFile ../../hosts/hp-victus-laptop/ssh_host_ed25519_key.pub;

    age.secrets.nix-builder-key.rekeyFile = ../../secrets/nix-builder/nix-builder-key.age;

    nix.distributedBuilds = true;
    nix.buildMachines = [
      {
        protocol = "ssh-ng";
        hostName = "hp-victus-laptop";
        sshUser = "nix-builder";
        sshKey = config.age.secrets.nix-builder-key.path;
        maxJobs = 8;
        speedFactor = 100;
        systems = ["x86_64-linux"];
        supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
      }
    ];
  };
}
