{
  flake.modules.homeManager.helix = {pkgs, ...}: {
    programs.helix.languages.language-server.harper-ls = {
      command = "${pkgs.harper}/bin/harper-ls";
      args = ["--stdio"];
      config.harper-ls.linters.SpellCheck = true;
    };
  };
}
