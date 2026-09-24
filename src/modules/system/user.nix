let
  keys = [
    ../../secrets/yubikey/yubikey_sshkey_usbc.pub
    ../../secrets/yubikey/yubikey_sshkey_usba.pub
  ];

  # Identity, spelled the same in both module sets. Everything else about this
  # account differs, so it is spelled per class below.
  #
  # `wheel` is the only group here, because it is the only one that is a fact
  # about who this account is rather than about which modules a host imports. A
  # group that exists because a module created it is that module's to grant -
  # `wireshark` and `gamemode` were both listed here and are now granted by
  # `wireshark` and `steam`, the modules that create them.
  account = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  hashedPassword = "$y$j9T$3SYXqLHQFhpwfTY8BHXmw.$cQGsYVD7CIWC22AJu1sX8qg4Po8Cyd00KzL9mAXa5F7";
in
{
  flake.modules.nixos.user =
    {
      config,
      pkgs,
      ...
    }:
    let
      user = config.constants.username;
    in
    {
      # Declaritivly manage users
      services.userborn.enable = true;

      security.pam.services.sudo.startSession = true;

      users = {
        mutableUsers = false;
        users = {
          ${user} = account // {
            openssh.authorizedKeys.keyFiles = keys;
            inherit hashedPassword;
            uid = config.constants.uid;
            shell = pkgs.nushell;
          };
        };
      };
    };

  flake.modules.finix.user =
    {
      config,
      pkgs,
      ...
    }:
    let
      user = config.constants.username;
    in
    {
      users.users.${user} = account // {
        # `hashedPassword` over there. finix names the hash for what it is
        # rather than for what it is not.
        password = hashedPassword;
        uid = config.constants.uid;
        shell = pkgs.nushell;
      };

      # NixOS implements `users.users.<name>.openssh.authorizedKeys.keyFiles` by
      # writing /etc/ssh/authorized_keys.d/<name> and pointing sshd at it. finix
      # has no such option, so the file is written here and the openssh module
      # says where to look — the same division of labour, just by hand.
      environment.etc."ssh/authorized_keys.d/${user}".source = pkgs.concatText "authorized_keys" keys;

      # Three things have no counterpart and are dropped rather than faked:
      #
      #   `users.mutableUsers = false` — finix has no such switch; it writes
      #   userborn.json and lets that tool own the accounts.
      #
      #   `services.userborn.enable` — the same thing, not an option here
      #   because it is how the users module already works.
      #
      #   `security.pam.services.sudo.startSession` — finix's pam has no
      #   per-service session switch.
    };
}
