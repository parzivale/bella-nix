{
  flake.modules.homeManager.helix = {pkgs, ...}: let
    deadnixEfm = pkgs.writeShellScript "deadnix-efm" ''
      ${pkgs.deadnix}/bin/deadnix --output-format json "$1" | \
        ${pkgs.jq}/bin/jq -r \
          --arg f "$1" \
          '.results[] | $f + ":" + (.line|tostring) + ":" + (.column|tostring) + ": " + .message'
    '';
  in {
    xdg.configFile."efm-langserver/config.yaml".text = ''
      version: 2
      languages:
        nix:
          - lint-command: "${pkgs.statix}/bin/statix check --stdin --format errfmt"
            lint-stdin: true
            lint-formats:
              - "<stdin>>%l:%c:%t:%n:%m"
          - lint-command: "${deadnixEfm} %f"
            lint-formats:
              - "%f:%l:%c: %m"
    '';

    programs.helix.languages = {
      language = [
        {
          name = "nix";
          auto-format = true;
          language-servers = [
            "nil"
            "harper-ls"
            {
              name = "efm-langserver";
              only-features = ["diagnostics"];
            }
          ];
          formatter = {
            command = "${pkgs.nixfmt-tree}/bin/treefmt";
            args = ["--stdin" "a.nix"];
          };
        }
      ];
      language-server.nil.command = "${pkgs.nil}/bin/nil";
      language-server.efm-langserver.command = "${pkgs.efm-langserver}/bin/efm-langserver";
    };
  };
}
