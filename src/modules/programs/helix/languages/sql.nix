{
  flake.modules.homeManager.helix = {pkgs, ...}: {
    programs.helix.languages = {
      language = [
        {
          name = "sql";
          auto-format = true;
          language-servers = ["sqls" "harper-ls"];
          formatter = {
            command = "${pkgs.sqlfluff}/bin/sqlfluff";
            args = ["format" "-"];
          };
        }
      ];
      language-server.sqls.command = "${pkgs.sqls}/bin/sqls";
    };
  };
}
