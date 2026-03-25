{
  flake.modules.nixos.zen = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.programs.zen-browser.profiles.${user} = rec {
      containersForce = true;
      containers = {
        "Personal" = {
          color = "blue";
          icon = "circle";
          id = 1;
        };
        "Work Cz" = {
          color = "purple";
          icon = "briefcase";
          id = 2;
        };

        "Work Oversoul" = {
          color = "turquoise";
          icon = "briefcase";
          id = 3;
        };
      };

      spacesForce = true;
      spaces = {
        "Personal" = {
          id = "4d929899-3c7c-44e3-be00-e1e850836b6f";
          icon = "🏡";
          position = 1000;
          container = containers.Personal.id;
        };
        "Work - CZ" = {
          id = "1aa8cdd7-cf7b-4523-a2aa-20d3f085dfd3";
          icon = "🧑‍💻";
          position = 2000;
          container = containers."Work Cz".id;
        };
        "Work - Oversoul" = {
          id = "70ce3ac1-b532-45dc-b95b-4c4d9161c142";
          icon = "🧑‍💻";
          position = 3000;
          container = containers."Work Oversoul".id;
        };
      };
    };
  };
}
