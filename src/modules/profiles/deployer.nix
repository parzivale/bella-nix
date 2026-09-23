let
  # A machine deployments are driven from. The only thing that makes one is
  # having the working copies, so that is all this says.
  deployer =
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      state.preserve.users.${user} = {
        directories = [
          {
            directory = "develop";
            mode = "0755";
          }
        ];
      };
    };
in
{
  flake.modules.nixos.deployer = deployer;
  flake.modules.finix.deployer = deployer;
}
