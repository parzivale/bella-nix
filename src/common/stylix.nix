{
  nixpkgs,
  vars,
  ...
}: let
  iconTheme = {
  };
in {
  stylix = {
    inherit iconTheme;
  };

  home-manager.users.${vars.username} = {
    stylix = {
      inherit iconTheme;
      targets.zen-browser.profileNames = ["${vars.username}"];
    };
  };
}
