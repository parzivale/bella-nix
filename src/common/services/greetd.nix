{...}: {
  settings = {
    default_session = {
      command = "niri-session -- env -u DISPLAY regreet";
      user = "greeter";
    };
  };
}
