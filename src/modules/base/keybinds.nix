{
  # Keybinds that launch something, declared without naming a compositor.
  #
  # A module that ships a program people press a key for - a terminal, a
  # launcher, a notification centre - knows the chord and the command, and
  # nothing else. Which compositor turns that into a binding is the host's
  # business, so it says so here and whichever compositor is configured reads
  # it, the same way `state.preserve` is written by modules and implemented by
  # whatever persists state.
  #
  # Only spawning. Every other kind of binding - focus this column, resize that
  # window - is the compositor describing itself, and belongs in the compositor's
  # own configuration rather than in a contract that pretends it is portable.
  flake.modules.generic.keybinds =
    { lib, ... }:
    {
      options.state.keybinds = lib.mkOption {
        type = with lib.types; attrsOf (listOf str);
        default = { };
        example = lib.literalExpression ''
          {
            "Mod+Return" = [ "wezterm" ];
            "XF86AudioRaiseVolume" = [ "wpctl" "set-volume" "@DEFAULT_SINK@" "5%+" ];
          }
        '';
        description = ''
          Chords to spawn, as the command and its arguments.

          The chord is spelled the way the compositor spells it — `Mod+Return`,
          `XF86MonBrightnessUp` — because niri, sway and hyprland already agree
          on that, and inventing a third spelling to translate from would buy
          nothing.
        '';
      };
    };
}
