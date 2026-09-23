{ inputs, ... }:
{
  flake.modules.nixos.remote-builder =
    { pkgs, ... }:
    {
      # A builder's output is consumed by other machines, so it signs what it
      # builds. `deployer` carries the same import for the same reason - those
      # two roles are the whole set of machines that hold the key.
      imports = [ inputs.self.modules.nixos.signed-nix ];

      users.groups.nix-build = { };
      users.users.nix-builder = {
        isSystemUser = true;
        group = "nix-build";
        shell = pkgs.bash;
        openssh.authorizedKeys.keyFiles = [ ../../secrets/master/nix-builder/nix-builder-key.pub ];
      };

      nix.settings.trusted-users = [ "nix-builder" ];
      services.openssh.settings.AllowUsers = [ "nix-builder" ];
    };
}
