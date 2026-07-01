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
      # QEMU linux-user has a race in TCG block-chaining when multiple guest
      # threads run concurrently: dlsym("_Unwind_Backtrace") returns NULL from
      # Node.js Worker Thread pthread_exit → glibc 2.42 fatal assert.
      # QEMU_LOG=nochain disables block-chaining to force serialised dispatch,
      # which avoids the buggy optimisation path.
      matrix-authentication-service = prev.matrix-authentication-service.overrideAttrs (_old: {
        QEMU_LOG = "nochain";
      });
    })
  ];

  services.getty.autologinUser = user;
}
