{
  flake.modules.homeManager.helix = {pkgs, ...}: {
    programs.helix.languages = {
      language = [
        {
          name = "nix";
          auto-format = true;
          language-servers = ["nil" "harper-ls"];
          formatter.command = "${pkgs.alejandra}/bin/alejandra";
        }
      ];
      language-server.nil.command = "${pkgs.nil}/bin/nil";
    };
  };
}
