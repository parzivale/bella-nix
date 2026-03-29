{...}: {
  flake.modules.nixos.use-x86-builders = {config, ...}: {
    programs.ssh.knownHosts."hp-victus-laptop".publicKey = builtins.readFile ../../hosts/hp-victus-laptop/ssh_host_ed25519_key.pub;

    nix.distributedBuilds = true;
    nix.buildMachines = [
      {
        hostName = "hp-victus-laptop";
        sshUser = "nix-builder";
        sshKey = config.age.secrets.nix-builder-key.path;
        maxJobs = 8;
        systems = ["x86_64-linux"];
        supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
      }
    ];
  };
}
