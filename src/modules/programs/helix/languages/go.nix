{
  flake.modules.homeManager.helix = {pkgs, ...}: {
    programs.helix.languages = {
      language = [
        {
          name = "go";
          auto-format = true;
          language-servers = ["gopls" "harper-ls"];
        }
      ];
      language-server.gopls.command = "${pkgs.gopls}/bin/gopls";
    };
  };
}
