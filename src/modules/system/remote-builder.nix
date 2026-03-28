{...}: {
  flake.modules.nixos.remote-builder = {...}: {
    users.groups.nix-build = {};
    users.users.nix-builder = {
      isSystemUser = true;
      group = "nix-build";
      openssh.authorizedKeys.keyFiles = [../../secrets/nix-builder/nix-builder-key.pub];
    };

    nix.settings.trusted-users = ["nix-builder"];
    services.openssh.settings.AllowUsers = ["nix-builder"];
  };
}
