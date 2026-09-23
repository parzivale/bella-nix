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
      user = config.systemConstants.username;
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

  flake.modules.finix.secrets = {
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

    # `age.identityPaths` is left alone: the community module reads it from
    # `services.openssh.settings.HostKey`, which our openssh module pins to
    # /etc/ssh/ssh_host_ed25519_key on this class too.
  };
}
