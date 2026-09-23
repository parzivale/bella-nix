{ inputs, ... }:
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
  # `signed-nix` lives here, and on `remote-builder`, rather than on
  # `deployable`. `secret-key-files` signs *locally-built* paths, so a target
  # that holds the deploy key stamps whatever its own users build with the one
  # signature the fleet trusts - which leaves a signature saying nothing about
  # where a closure came from. Only machines that produce closures for others
  # hold the key; every machine trusts it, through `trusted-public-keys` in
  # `nix`. That is what makes the check in `deploy-user` mean something.
  flake.modules.nixos.deployer = {
    imports = [
      deployer
      inputs.self.modules.nixos.signed-nix
    ];
  };

  flake.modules.finix.deployer = {
    imports = [
      deployer
      inputs.self.modules.finix.signed-nix
    ];
  };
}
