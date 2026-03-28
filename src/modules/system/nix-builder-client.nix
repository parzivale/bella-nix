{...}: {
  flake.modules.nixos.nix-builder-client = {...}: {
    users.groups.nix-build = {};
    users.users.nix-builder = {
      isSystemUser = true;
      group = "nix-build";
      openssh.authorizedKeys.keyFiles = [../../secrets/nix-builder/nix-builder.pub];
    };

    nix.settings.trusted-users = ["nix-builder"];
    services.openssh.settings.AllowUsers = ["nix-builder"];
    nix.distributedBuilds = true;
  };
}
