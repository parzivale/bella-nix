{nixpkgs, ...}: {
  config.services.openssh = {
    # Ssh should always be enabled
    # as rekey expects the public key
    # to decrypt secrets
    enable = nixpkgs.lib.mkDefault true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    hostKeys = [
      "/etc/ssh/ssh_host_ed25519_key"
    ];
  };
}
