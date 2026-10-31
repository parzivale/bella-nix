{ inputs, ... }:
let
  # The same module for nixos and finix; `class` only picks which home-manager it imports.
  module =
    class:
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      imports = [ inputs.self.modules.${class}.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.helix ];
    };
in
{
  flake.modules.homeManager.helix =
    { pkgs, ... }:
    {
      programs.helix = {
        enable = true;
        defaultEditor = true;
        extraPackages = with pkgs; [
          cargo
          statix
          deadnix
          nixfmt-tree
          efm-langserver
        ];
        settings.editor = {
          bufferline = "multiple";
          statusline = {
            left = [
              "mode"
              "spinner"
              "register"
            ];
            center = [
              "version-control"
              "spacer"
              "separator"
              "file-name"
            ];
            right = [
              "diagnostics"
              "workspace-diagnostics"
              "position"
              "file-encoding"
              "file-line-ending"
              "file-type"
            ];
            separator = "|";
            mode = {
              normal = "NORMAL";
              insert = "INSERT";
              select = "SELECT";
            };
          };
          lsp.display-inlay-hints = true;
          whitespace.characters = {
            space = "·";
            nbsp = "⍽";
            nnbsp = "␣";
            tab = "→";
            newline = "⏎";
            tabpad = "·";
          };
          indent-guides = {
            render = true;
            character = "▏";
            skip-levels = 1;
          };
        };
      };
    };

  flake.modules.nixos.helix = module "nixos";
  flake.modules.finix.helix = module "finix";
}
