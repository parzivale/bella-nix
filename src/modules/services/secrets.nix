{ inputs, ... }:
let
  # The same secrets, rekeyed the same way, whichever class evaluates the host.
  # agenix-rekey's own module is class-neutral - it touches no systemd and no
  # activation scripts - so both classes import it directly; only the module
  # that installs the secrets at boot differs.
  rekey =
    { config, pkgs, ... }:
    {
      age.rekey = {
        masterIdentities = [
          ../../secrets/yubikey/yubikey_identity_usbc.pub
          ../../secrets/yubikey/yubikey_identity_usba.pub
        ];
        agePlugins = [ pkgs.age-plugin-fido2-hmac ];

        storageMode = "local";
        localStorageDir = ../../secrets/rekeyed/${config.networking.hostName};
      };
    };
in
{
  flake.modules.nixos.secrets =
    {
      config,
      pkgs,
      ...
    }:
    let
      user = config.constants.username;
    in
    {
      imports = [
        rekey
        inputs.self.modules.nixos.home-manager
        inputs.agenix.nixosModules.default
        inputs.agenix-rekey.nixosModules.default
      ];

      home-manager.users.${user}.home = {
        packages = with pkgs; [
          age
          age-plugin-fido2-hmac
        ];
      };

      systemd.services.agenix-install-secrets = {
        after = [ "preservation.target" ];
        requires = [ "preservation.target" ];
      };
    };

  flake.modules.finix.secrets =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [
        rekey

        # ryantm/agenix' nixos module ported onto `providers.services`: the
        # options and the install script are the same, the systemd unit is a
        # oneshot on sysinit instead.
        inputs.community-modules.nixosModules.agenix

        # Unported, because it needs no port - it only computes where a rekeyed
        # secret lives and points `age.secrets.<name>.file` at it.
        inputs.agenix-rekey.nixosModules.default
      ];

      # No secrets in a virtual machine, and nothing stalling because of it.
      #
      # A machine's secrets are encrypted to that machine's ssh host key. A VM built from its
      # configuration generates a fresh key on first boot and so cannot decrypt any of them, and
      # it should not be handed the real one: the store is world readable.
      #
      # The way that failed is the point. `agenix-install-secrets` exited 1, its readiness
      # companion waited for a success which was never coming, and since the unit is attached to
      # `sysinit` the whole trunk stopped behind it. The machine booted to nothing, silently.
      #
      # Emptying `age.secrets` is not the answer: the set is read at evaluation time all over the
      # configuration - `config.age.secrets.tailscale_token.path` and friends - so removing it
      # breaks the build rather than the boot. The secrets stay declared; what changes is that
      # the unit which cannot succeed is replaced by one which says so and does.
      #
      # What this costs, stated plainly: no decrypted secret exists in the VM. Anything reading
      # one fails where it reads it, which is a legible place to fail, instead of before the
      # machine has finished starting.
      virtualisation.vmVariant.providers.services.units.agenix-install-secrets.type.oneshot.command =
        lib.mkForce (
          toString (
            pkgs.writeShellScript "agenix-install-secrets-vm" ''
              echo "[agenix] this is a virtual machine: no host key that can decrypt ${toString (builtins.length (builtins.attrNames config.age.secrets))} secret(s), so none are installed" >&2
            ''
          )
        );

      # `age.identityPaths` is left alone: the community module reads it from
      # `services.openssh.settings.HostKey`, which our openssh module pins to
      # /etc/ssh/ssh_host_ed25519_key on this class too.
    };
}
