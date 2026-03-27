{
  flake.modules.nixos.openssh = {
    lib,
    config,
    ...
  }: {
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = lib.mkDefault "no";
        AllowUsers = [config.systemConstants.username];
      };

      generateHostKeys = true;

      hostKeys = [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
    };
  };
}
