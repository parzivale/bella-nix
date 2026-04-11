{inputs, ...}: {
  flake.modules.nixos.wired = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    home-manager.users.${user} = {
      imports = [inputs.wired-notify.homeManagerModules.default];

      services.wired = {
        enable = true;
        package = inputs.wired-notify.packages.${pkgs.system}.default;
        config = pkgs.writeText "wired.ron" ''
          (
              max_notifications: 0,
              timeout: 10000,
              idle_threshold: 120,
              icon_theme: "Adwaita",
              zero_timeout: NeverExpire,
              layout_blocks: [
                  (
                      name: "root",
                      parent: "",
                      droppable: false,
                      pos_x: 0,
                      pos_y: 0,
                      width: 200,
                      height: 100,
                      anchor: TopRight,
                      margin: 10,
                      padding: 0,
                      border: (width: 0, color: (r: 0.0, g: 0.0, b: 0.0, a: 0.0)),
                      background: (color: (r: 0.157, g: 0.157, b: 0.157, a: 0.95), modifier_type: None, modifier: 0.0),
                      text: (
                          font: "Monospace 11",
                          foreground: (r: 0.922, g: 0.859, b: 0.714, a: 1.0),
                          alignment: Left,
                          ellipsize: End,
                          word_wrap: true,
                      ),
                  ),
                  (
                      name: "image",
                      parent: "root",
                      droppable: false,
                      pos_x: 5,
                      pos_y: 5,
                      width: 48,
                      height: 48,
                      anchor: TopLeft,
                      margin: 0,
                      padding: 0,
                      border: (width: 0, color: (r: 0.0, g: 0.0, b: 0.0, a: 0.0)),
                      background: (color: (r: 0.0, g: 0.0, b: 0.0, a: 0.0), modifier_type: None, modifier: 0.0),
                      text: (
                          font: "Monospace 11",
                          foreground: (r: 0.0, g: 0.0, b: 0.0, a: 0.0),
                          alignment: Center,
                          ellipsize: End,
                          word_wrap: false,
                      ),
                  ),
                  (
                      name: "summary",
                      parent: "root",
                      droppable: false,
                      pos_x: 58,
                      pos_y: 5,
                      width: 150,
                      height: 20,
                      anchor: TopLeft,
                      margin: 0,
                      padding: 0,
                      border: (width: 0, color: (r: 0.0, g: 0.0, b: 0.0, a: 0.0)),
                      background: (color: (r: 0.0, g: 0.0, b: 0.0, a: 0.0), modifier_type: None, modifier: 0.0),
                      text: (
                          font: "Monospace Bold 11",
                          foreground: (r: 0.922, g: 0.859, b: 0.714, a: 1.0),
                          alignment: Left,
                          ellipsize: End,
                          word_wrap: false,
                      ),
                  ),
                  (
                      name: "body",
                      parent: "root",
                      droppable: false,
                      pos_x: 58,
                      pos_y: 28,
                      width: 250,
                      height: 72,
                      anchor: TopLeft,
                      margin: 0,
                      padding: 0,
                      border: (width: 0, color: (r: 0.0, g: 0.0, b: 0.0, a: 0.0)),
                      background: (color: (r: 0.0, g: 0.0, b: 0.0, a: 0.0), modifier_type: None, modifier: 0.0),
                      text: (
                          font: "Monospace 11",
                          foreground: (r: 0.922, g: 0.859, b: 0.714, a: 1.0),
                          alignment: Left,
                          ellipsize: End,
                          word_wrap: true,
                      ),
                  ),
              ],
              urgencies: [
                  (
                      name: "low",
                      text_foreground: (r: 0.922, g: 0.859, b: 0.714, a: 1.0),
                      background: (color: (r: 0.157, g: 0.157, b: 0.157, a: 0.95), modifier_type: None, modifier: 0.0),
                      border: (width: 0, color: (r: 0.0, g: 0.0, b: 0.0, a: 0.0)),
                  ),
                  (
                      name: "normal",
                      text_foreground: (r: 0.922, g: 0.859, b: 0.714, a: 1.0),
                      background: (color: (r: 0.157, g: 0.157, b: 0.157, a: 0.95), modifier_type: None, modifier: 0.0),
                      border: (width: 0, color: (r: 0.0, g: 0.0, b: 0.0, a: 0.0)),
                  ),
                  (
                      name: "critical",
                      text_foreground: (r: 0.922, g: 0.859, b: 0.714, a: 1.0),
                      background: (color: (r: 0.157, g: 0.157, b: 0.157, a: 0.95), modifier_type: None, modifier: 0.0),
                      border: (width: 2, color: (r: 0.984, g: 0.286, b: 0.204, a: 1.0)),
                  ),
              ],
              shortcuts: (
                  notification_interact: [(mouse: Left, modifiers: [])],
                  notification_close: [(mouse: Right, modifiers: [])],
                  notification_action_1: [(mouse: Middle, modifiers: [])],
              ),
          )
        '';
      };
    };
  };
}
