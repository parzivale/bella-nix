{ inputs }:
{
  config,
  lib,
  pkgs,
  modules,
  ...
}:
let
  path = ./ssh_host_ed25519_key.pub;
  key = if builtins.pathExists path then builtins.readFile path else "";
  user = config.constants.username;
in
{
  networking.hostName = "macbook";

  imports =
    (with inputs.self.modules.finix; [
      system
      secrets
      home-manager
      cli
      deployer
      deployable
      desktop
      remote-builder
      # hardware
      iwd
      zram
      # power
      upower
      poweralertd
      # system
      wireshark
      use-x86-builders
    ])
    ++ [
      # FEX, below. binfmt_misc registration is a finix module of its own rather than part of
      # the always-loaded set, so it is named here.
      modules.binfmt
    ];

  finit.enable = true;

  # x86_64 Wine, through FEX rather than qemu.
  #
  # The nixos host's comment claimed qemu took priority over this by alphabetical registration
  # order, from `boot.binfmt.emulatedSystems` - but that list was empty and had been for a
  # while, so FEX was the only registration on the machine and the ordering never mattered.
  # Nothing derives qemu registrations here either; a system to emulate would be named the same
  # way this is.
  boot.binfmt.registrations.fex-x86_64 = {
    interpreter = "${pkgs.fex-headless}/bin/FEXInterpreter";
    magicOrExtension = ''\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00'';
    mask = ''\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff'';
  };

  # 24GB, on the persistent subvolume. No `size`: nixos creates a swapfile it is given a size
  # for, and finix mounts what is already there - so the file is made once, out of band, with
  #
  #   btrfs filesystem mkswapfile --size 24g /persistent/swapfile
  swapDevices = [
    {
      device = "/persistent/swapfile";
      priority = 1;
    }
  ];

  hardware.facter.reportPath = ./facter.json;
  age.rekey.hostPubkey = lib.mkIf (key != "") key;

  services.getty.autologinUser = user;

  # The nixos host emptied `tailscaled-autoconnect`'s `wantedBy`, and this is the same thing
  # said here: community-modules' tailscale module calls its unit `tailscale-up`, and nothing
  # in the graph requires it, so disabling it strands nothing.
  #
  # Which is safe because the join is not what this does. `/var/lib/tailscale` is preserved, so
  # the node stays authenticated across a reboot and `tailscaled` brings the interface up from
  # that state on its own. `tailscale up` re-running every boot - re-asserting the auth key and
  # the tags - is what the unit is for, and a laptop which joined once does not need it.
  #
  # The consequence to know about: a machine which has never joined, or whose state was wiped,
  # will not join by itself. Enable this for that boot.
  providers.services.units.tailscale-up.enable = false;

  # `security.polkit.enablePkexecWrapper` has no counterpart: finix's polkit module installs
  # the setuid pkexec wrapper whenever polkit is enabled, so there is nothing to turn on.

  boot.kernelParams = [ "button.lid_init_state=open" ];

  services.elogind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "suspend";
    # Respect handle-lid-switch inhibitors, so the resume hook below can block stale close
    # events after wake
    LidSwitchIgnoreInhibited = "no";
    # Shortened from the 30s default - the inhibitor covers the race window, so 30s of
    # lid-close being ignored after wake is not needed
    HoldoffTimeoutSec = "3";
  };

  # The stale lid-close event this machine delivers on resume, which would otherwise put it
  # straight back to sleep.
  #
  # `powerManagement.resumeCommands` on nixos; here it is a `providers.resumeAndSuspend` hook,
  # which elogind implements by running it out of /etc/elogind/system-sleep. Backgrounded, as
  # it was there: the hook is run before the resume completes and a foreground sleep would hold
  # it up for the full three seconds.
  providers.resumeAndSuspend.hooks.swallow-stale-lid-close = {
    event = "resume";

    action = ''
      ${lib.getExe' config.services.elogind.package "elogind-inhibit"} \
        --what=handle-lid-switch \
        --who=post-resume-delay \
        --why="Swallow stale lid-close event after resume" \
        --mode=block \
        ${lib.getExe' pkgs.coreutils "sleep"} 3 &
    '';
  };

  home-manager.users.${user} =
    { pkgs, ... }:
    {
      home = {
        stateVersion = "25.11";
        packages = [ pkgs.brightnessctl ];
      };

      programs.niri.settings = {
        input = {
          touchpad.scroll-factor = 0.5;
          keyboard.xkb.layout = "es";
        };
        binds = {
          "XF86MonBrightnessUp".action.spawn = [
            "brightnessctl"
            "set"
            "5%+"
          ];
          "XF86MonBrightnessDown".action.spawn = [
            "brightnessctl"
            "set"
            "5%-"
          ];
          "XF86KbdBrightnessUp".action.spawn = [
            "brightnessctl"
            "-d"
            "apple::kbd_backlight"
            "set"
            "5%+"
          ];
          "XF86KbdBrightnessDown".action.spawn = [
            "brightnessctl"
            "-d"
            "apple::kbd_backlight"
            "set"
            "5%-"
          ];
        };
      };
    };
}
