{ inputs, ... }:
let
  # The theme, which is neither class's business: the same options either way.
  # On nixos the nixos module takes them and passes them down to home-manager
  # itself; on finix there is no nixos module to do that, so they are set on the
  # home directly. Hence a function of the two things that differ.
  theme = pkgs: image: {
    enable = true;
    inherit image;
    base16Scheme = ./themes/catppuccin-macchiato.yaml;
    icons = {
      package = pkgs.papirus-icon-theme;
      dark = "Papirus-Dark";
      enable = true;
    };
    cursor = {
      package = pkgs.nordzy-cursor-theme;
      name = "Nordzy-cursors";
      size = 32;
    };
    fonts = {
      sansSerif = {
        package = pkgs.atkinson-hyperlegible-next;
        name = "Atkinson Hyperlegible Next";
      };
      serif = {
        package = pkgs.atkinson-hyperlegible-next;
        name = "Atkinson Hyperlegible Next";
      };
      monospace = {
        package = pkgs.maple-mono.NF-CN;
        name = "Maple Mono NF CN";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
      sizes.popups = 14;
    };
  };
in
{
  flake.modules.homeManager.stylix =
    { osConfig, ... }:
    let
      user = osConfig.constants.username;
    in
    {
      stylix.targets.zen-browser.profileNames = [ user ];
      xdg.desktopEntries = {
        qt5ct = {
          name = "Qt5 Settings";
          noDisplay = true;
        };
        qt6ct = {
          name = "Qt6 Settings";
          noDisplay = true;
        };
        kvantummanager = {
          name = "Kvantum Manager";
          noDisplay = true;
        };
      };
    };

  flake.modules.nixos.stylix =
    {
      pkgs,
      config,
      ...
    }:
    let
      user = config.constants.username;
    in
    {
      imports = [
        inputs.stylix.nixosModules.default
        inputs.self.modules.nixos.home-manager
      ];
      programs.dconf.enable = true;

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.stylix ];

      stylix = theme pkgs config.constants.bg_img;
    };

  # stylix's nixos module carries `_class = "nixos"`, so it cannot be imported
  # into a finix evaluation at all - this is not a choice between the two halves,
  # it is the only half available. Its home module is unclassed and is the one
  # doing the work: the core options (colours, fonts, icons, cursor, palette) are
  # class-neutral files both halves import, and of the targets, gtk, qt,
  # fontconfig and font-packages all have a home-manager implementation too. So
  # what moves is where the options are set, not what they do.
  #
  # Genuinely nixos-only: chromium, console, grub, kmscon, lightdm, limine,
  # plymouth, regreet. Of those, only `console` does anything on these machines -
  # grub and limine because the boot loader is systemd-boot, lightdm and regreet
  # because greetd starts the session with no greeter, plymouth and kmscon
  # because neither is enabled, and chromium because stylix's own target turns
  # `programs.chromium` on to write a policy file for a browser nothing here
  # installs. `console` is restored below.
  flake.modules.finix.stylix =
    { config, pkgs, ... }:
    let
      user = config.constants.username;
      colors = config.home-manager.users.${user}.lib.stylix.colors;
    in
    {
      imports = [
        inputs.self.modules.finix.home-manager
        inputs.self.modules.finix.user
      ];

      # What `programs.dconf.enable` does on the other side, which there is no module for here:
      # put dconf where a session bus can find its service file. home-manager's activation has a
      # `dconfSettings` step that loads the settings stylix generates, and with no
      # ca.desrt.dconf.service on XDG_DATA_DIRS the bus it spawns cannot start the service:
      #
      #   error: GDBus.Error:org.freedesktop.DBus.Error.ServiceUnknown:
      #     The name ca.desrt.dconf was not provided by any .service files
      #
      # which fails activation - after it has linked the home files, so the damage is not that
      # the configuration is missing but that the unit never reports success, and anything
      # ordered behind it waits for a success that is not coming.
      #
      # /share/dbus-1 is already in `environment.pathsToLink`, so the package being in the system
      # profile is all that is needed.
      environment.systemPackages = [
        pkgs.dconf
        pkgs.fontconfig
      ];

      # And fontconfig itself, which nothing had turned on: `fonts.fontconfig.enable` was false
      # on both finix hosts and true on every nixos one, where it defaults that way.
      #
      # So there was no /etc/fonts/fonts.conf and no /etc/fonts/conf.d at all, and with no system
      # configuration to load fontconfig falls back to a compiled-in default which knows about no
      # font directories and does not read the user's conf.d either. Which is how every font can
      # be present and none of them usable: the home half below sets home-manager's own
      # `fonts.fontconfig.enable`, which writes ~/.config/fontconfig/conf.d/10-hm-fonts.conf
      # naming the directory the 32 faces are in - and nothing ever read the file. Half of this
      # was fixed there and the other half was never noticed, for the same reason as always: it
      # fails by doing nothing.
      #
      # The fontconfig binaries go in with it, because without fc-match and fc-list there is no
      # way to ask the machine the question. The first attempt at diagnosing this read
      # `fc-list | wc -l` as "zero fonts" when it meant "no such command".
      fonts.fontconfig.enable = true;

      home-manager.users.${user} =
        {
          pkgs,
          osConfig,
          ...
        }:
        {
          imports = [
            # On nixos the nixos module imports this into home-manager itself.
            # There is nothing here doing that, so it is named.
            inputs.stylix.homeModules.stylix
            inputs.self.modules.homeManager.stylix
          ];

          # Both of the settings below are on by default under nixos and off here,
          # for one reason: home-manager's nixos module passes a `nixosConfig`
          # specialArg and the community-modules port does not, so anything asking
          # "am I inside a system configuration?" gets the standalone answer. Two
          # things in this stack ask.
          stylix = theme pkgs osConfig.constants.bg_img // {
            # `autoEnable = nixosConfig != null`, so the Kvantum and qt5ct/qt6ct
            # configuration was simply not generated - which the desktop entries
            # this module's home half hides imply is there.
            targets.qt.enable = true;
          };

          # Defaults to `nixosConfig != null && nixosConfig.home-manager.useUserPackages
          # && nixosConfig.fonts.fontconfig.enable`. Without it the font names
          # stylix picks are written nowhere an application reads.
          fonts.fontconfig.enable = true;
        };

      # What stylix's console target sets, read off the palette its home module
      # generated - finix has the option, so the one target that would otherwise
      # be lost is a matter of saying where the numbers come from. Under
      # `hardware.console`, `console` being a renamed alias finix warns about.
      # Order is the target's: eight normal then eight bright, the six named
      # colours repeated across both halves.
      hardware.console.colors = with colors; [
        base00-hex
        red
        green
        yellow
        blue
        magenta
        cyan
        base05-hex
        base03-hex
        red
        green
        yellow
        blue
        magenta
        cyan
        base07-hex
      ];
    };
}
