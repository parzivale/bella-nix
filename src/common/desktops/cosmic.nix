{...}: {
  wayland.desktopManager.cosmic = {
    enable = true;
    compositor = {
      active_hint = true;
      focus_follows_cursor = true;
      input_default = {
      };
    };
  };
}
