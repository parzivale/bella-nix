{
  flake.modules.nixos._1password =
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      programs._1password.enable = true;
      programs._1password-gui = {
        enable = true;
        polkitPolicyOwners = [ user ];
      };
      state.preserve.users.${user} = {
        directories = [
          {
            directory = ".config/1Password";
            mode = "0700";
          }
          {
            directory = ".config/op";
            mode = "0700";
          }
        ];
      };
    };
}
