{ inputs, ... }:
let
  # The same node, joined the same way, on either class.
  tailnet =
    { config, ... }:
    {
      age.secrets.tailscale_token.rekeyFile = ../../secrets/master/tailscale/tailscale_key.age;

      services.tailscale = {
        enable = true;
        authKeyFile = config.age.secrets.tailscale_token.path;
        authKeyParameters = {
          preauthorized = true;
          ephemeral = false;
        };
        extraUpFlags = [ "--advertise-tags=tag:nixos" ];
      };

      state.preserve.directories = [
        {
          directory = "/var/lib/tailscale";
          mode = "0700";
        }
      ];
    };
in
{
  flake.modules.nixos.tailscale = {
    imports = [
      tailnet
      inputs.self.modules.nixos.secrets
    ];

    systemd.services = {
      tailscaled-autoconnect.after = [
        "agenix-install-secrets.service"
        "network-online.target"
      ];
      tailscaled-autoconnect.requires = [
        "agenix-install-secrets.service"
        "network-online.target"
      ];
      nginx.after = [ "tailscaled-autoconnect.service" ];
      nginx.wants = [ "tailscaled-autoconnect.service" ];
    };

    services.tailscale.disableTaildrop = true;
  };

  flake.modules.finix.tailscale = {
    imports = [
      tailnet
      inputs.self.modules.finix.secrets
      inputs.community-modules.nixosModules.tailscale
    ];

    providers.services.units = {
      # `disableTaildrop` is a nixpkgs convenience for an environment variable
      # the daemon reads, and a unit here takes an environment directly.
      tailscaled.environment.TS_DISABLE_TAILDROP = "true";

      # The community module already has this after `tailscaled`; the key has
      # to be decrypted before it can be read, which the nixos side says as an
      # ordering on agenix-install-secrets.service.
      tailscale-up.requires = [ "agenix-install-secrets" ];
    };

    # Not in a virtual machine. `tailscale up` needs the auth key, which is a secret, and a VM
    # has none - see the note in `secrets`. With the agenix unit gone this one would be left
    # requiring something which will never be ready, which is a branch of the graph that waits
    # for ever rather than one that fails.
    #
    # The daemon still runs. What does not happen is joining the tailnet, which a throwaway
    # machine has no business doing under this host's identity anyway.
    virtualisation.vmVariant.providers.services.units.tailscale-up.enable = false;

    # Nothing corresponds to the nginx ordering: that host runs nginx behind
    # the tailnet on nixos, and no finix host of mine serves anything yet.
  };
}
