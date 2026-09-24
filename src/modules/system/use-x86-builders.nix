{ inputs, ... }:
let
  hostName = "hp-victus-laptop";
  hostKey = ../../hosts/nixos/hp-victus-laptop/ssh_host_ed25519_key.pub;

  # As in `use-arm-builders`: one value, taken by the same submodule on both
  # sides.
  machine = sshKey: {
    protocol = "ssh-ng";
    inherit hostName;
    sshUser = "nix-builder";
    inherit sshKey;
    maxJobs = 8;
    speedFactor = 100;
    systems = [
      "x86_64-linux"
      "i686-linux"
    ];
    supportedFeatures = [
      "nixos-test"
      "benchmark"
      "big-parallel"
      "kvm"
    ];
  };

  keyFile = ../../secrets/master/nix-builder/nix-builder-key.age;
in
{
  flake.modules.nixos.use-x86-builders =
    { config, ... }:
    {
      imports = [ inputs.self.modules.nixos.secrets ];

      programs.ssh.knownHosts.${hostName}.publicKey = builtins.readFile hostKey;

      age.secrets.nix-builder-key.rekeyFile = keyFile;

      nix.distributedBuilds = true;
      nix.settings.builders-use-substitutes = true;
      nix.buildMachines = [ (machine config.age.secrets.nix-builder-key.path) ];
    };

  flake.modules.finix.use-x86-builders =
    { config, modules, ... }:
    {
      imports = [
        inputs.self.modules.finix.secrets
        modules.ssh
        # As in use-arm-builders: the daemon has to be on, not merely declared.
        inputs.self.modules.finix.nix
      ];

      programs.ssh = {
        enable = true;
        knownHosts.${hostName}.publicKey = builtins.readFile hostKey;
      };

      age.secrets.nix-builder-key.rekeyFile = keyFile;

      services.nix-daemon = {
        distributedBuilds = true;
        settings.builders-use-substitutes = true;
        buildMachines = [ (machine config.age.secrets.nix-builder-key.path) ];
      };
    };
}
