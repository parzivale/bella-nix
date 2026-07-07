{ inputs }:
{
  config,
  lib,
  ...
}:
let
  path = ./ssh_host_ed25519_key.pub;
  key = if builtins.pathExists path then builtins.readFile path else "";
  user = config.systemConstants.username;
in
{
  imports = with inputs.self.modules.nixos; [
    cli
    server
    # services
    grocy
    matrix
    kanidm
    router
    postgres
    monitoring
    hookshot
  ];

  system.stateVersion = "25.11";
  home-manager.users.${user}.home.stateVersion = "25.11";

  services.tailscale = {
    extraUpFlags = [ "--advertise-exit-node" ];
    useRoutingFeatures = "server";
  };

  hardware.facter.reportPath = ./facter.json;
  age.rekey.hostPubkey = lib.mkIf (key != "") key;

  nixpkgs.overlays = [
    (final: prev: {
      # Upstream's .cargo/config.toml targets x86-64-v2 (SSE4.2+), which the
      # Xeon E5420 (SSE4.1 max) cannot execute — mas-cli SIGILLs on pcmpgtq.
      # The RUSTFLAGS env var takes precedence over config-file rustflags,
      # forcing the baseline x86-64 target.
      matrix-authentication-service = prev.matrix-authentication-service.overrideAttrs (_old: {
        RUSTFLAGS = "-C target-cpu=x86-64";
      });
    })
  ];

  services.getty.autologinUser = user;
}
