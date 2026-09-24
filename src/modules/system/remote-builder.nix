{ inputs, ... }:
let
  # The account builds arrive as. Its key is the one a client presents; nothing
  # else may log in with it.
  account = {
    isSystemUser = true;
    group = "nix-build";
  };

  keys = [ ../../secrets/master/nix-builder/nix-builder-key.pub ];
in
{
  flake.modules.nixos.remote-builder =
    { pkgs, ... }:
    {
      # A builder's output is consumed by other machines, so it signs what it
      # builds. `deployer` carries the same import for the same reason - those
      # two roles are the whole set of machines that hold the key.
      imports = [
        inputs.self.modules.nixos.signed-nix
        inputs.self.modules.nixos.openssh
      ];

      users.groups.nix-build = { };
      users.users.nix-builder = account // {
        shell = pkgs.bash;
        openssh.authorizedKeys.keyFiles = keys;
      };

      nix.settings.trusted-users = [ "nix-builder" ];
      services.openssh.settings.AllowUsers = [ "nix-builder" ];
    };

  flake.modules.finix.remote-builder =
    { pkgs, ... }:
    {
      imports = [
        inputs.self.modules.finix.signed-nix
        inputs.self.modules.finix.openssh
      ];

      users.groups.nix-build = { };
      users.users.nix-builder = account // {
        shell = pkgs.bash;
      };

      # `nix.settings` over there; the daemon owns its own configuration here,
      # the same split `signed-nix` makes.
      services.nix-daemon.settings.trusted-users = [ "nix-builder" ];
      services.openssh.settings.AllowUsers = [ "nix-builder" ];

      # As in `user`: finix has no
      # `users.users.<name>.openssh.authorizedKeys.keyFiles`, so the file goes
      # where sshd's AuthorizedKeysFile already points and the openssh module
      # says where that is.
      environment.etc."ssh/authorized_keys.d/nix-builder".source = pkgs.concatText "authorized_keys" keys;
    };
}
