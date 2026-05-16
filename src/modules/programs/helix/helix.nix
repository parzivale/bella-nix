{
  flake.modules.nixos.helix = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user}.programs.helix = {
      enable = true;
      defaultEditor = true;
      extraPackages = with pkgs; [
        cargo
      ];
      settings.editor = {
        bufferline = "multiple";
        statusline = {
          left = ["mode" "spinner" "register"];
          center = ["version-control" "spacer" "separator" "file-name"];
          right = [
            "diagnostics"
            "workspace-diagnostics"
            "position"
            "file-encoding"
            "file-line-ending"
            "file-type"
          ];
          separator = "|";
          mode.normal = "NORMAL";
          mode.insert = "INSERT";
          mode.select = "SELECT";
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
}
