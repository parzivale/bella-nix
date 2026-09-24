{ inputs, ... }:
let
  hostName = "macbook";
  hostKey = ../../hosts/nixos/macbook/ssh_host_ed25519_key.pub;

  # What the builder is, said once. `nix.buildMachines` on nixos and
  # `services.nix-daemon.buildMachines` on finix take the same submodule - the
  # finix one is a port of it - so the value itself carries over unchanged.
  machine = sshKey: {
    protocol = "ssh-ng";
    inherit hostName;
    sshUser = "nix-builder";
    inherit sshKey;
    systems = [ "aarch64-linux" ];
    maxJobs = 8;
    speedFactor = 100;
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
  flake.modules.nixos.use-arm-builders =
    { config, ... }:
    {
      imports = [ inputs.self.modules.nixos.secrets ];

      programs.ssh.knownHosts.${hostName}.publicKey = builtins.readFile hostKey;

      age.secrets.nix-builder-key.rekeyFile = keyFile;

      nix.distributedBuilds = true;
      nix.settings.builders-use-substitutes = true;
      nix.buildMachines = [ (machine config.age.secrets.nix-builder-key.path) ];
    };

  flake.modules.finix.use-arm-builders =
    { config, modules, ... }:
    {
      imports = [
        inputs.self.modules.finix.secrets
        # The client, not sshd: finix had neither an ssh client module nor
        # `buildMachines` until they were added for this.
        modules.ssh
        # Not `modules.nix-daemon`: that declares the options, and something has
        # to have turned the daemon on for any of them to be read. On nixos the
        # daemon is simply there; here it is opted into, and this module is no
        # use without it.
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
