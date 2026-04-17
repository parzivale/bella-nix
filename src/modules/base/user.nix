{
  flake.modules.nixos.user = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    # Declaritivly manage users
    services.userborn.enable = true;

    security.pam.services.sudo.startSession = true;

    systemd.additionalUpstreamSystemUnits = ["systemd-soft-reboot.service"];

    # Grant wheel unconditional yes for power actions (same as Fedora's 49-wheel.rules).
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if ((action.id == "org.freedesktop.login1.reboot" ||
             action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
             action.id == "org.freedesktop.login1.reboot-ignore-inhibit" ||
             action.id == "org.freedesktop.login1.power-off" ||
             action.id == "org.freedesktop.login1.power-off-multiple-sessions" ||
             action.id == "org.freedesktop.login1.power-off-ignore-inhibit") &&
            subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });
    '';

    users = {
      mutableUsers = false;
      users = {
        ${user} = {
          openssh.authorizedKeys.keyFiles = [../../secrets/yubikey/yubikey_sshkey.pub];
          isNormalUser = true;
          hashedPassword = "$y$j9T$3SYXqLHQFhpwfTY8BHXmw.$cQGsYVD7CIWC22AJu1sX8qg4Po8Cyd00KzL9mAXa5F7";
          extraGroups = ["wheel"];
          uid = config.systemConstants.uid;
          shell = pkgs.nushell;
        };
      };
    };
  };
}
