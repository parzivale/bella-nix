{
  vars,
  lib,
  ...
}: {
  services.openssh = {
    # Ssh should always be enabled
    # as rekey expects the public key
    # to decrypt secrets
    enable = lib.mkDefault true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = [vars.username];
    };
    generateHostKeys = lib.mkDefault true;

    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };
}
