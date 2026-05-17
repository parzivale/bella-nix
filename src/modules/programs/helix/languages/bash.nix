{
  flake.modules.homeManager.helix = {pkgs, ...}: {
    programs.helix.languages = {
      language = [
        {
          name = "bash";
          auto-format = true;
          language-servers = ["bash-language-server" "harper-ls"];
          formatter.command = "${pkgs.shfmt}/bin/shfmt";
        }
      ];
      language-server.bash-language-server = {
        command = "${pkgs.bash-language-server}/bin/bash-language-server";
        args = ["start"];
      };
    };
  };
}
