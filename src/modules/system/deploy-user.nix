{...}: {
  flake.modules.nixos.deploy-user = {pkgs, ...}: {
    users.users.deploy = {
      isSystemUser = true;
      group = "deploy";
      shell = pkgs.bash;
      openssh.authorizedKeys.keyFiles = [
        ../../secrets/yubikey/yubikey_sshkey_usbc.pub
        ../../secrets/yubikey/yubikey_sshkey_usba.pub
      ];
    };
    users.groups.deploy = {};

    services.openssh.settings.AllowUsers = ["deploy"];

    security.sudo.extraRules = [
      {
        users = ["deploy"];
        commands = [
          {
            command = "/nix/store/*/activate-rs *";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];
  };
}
