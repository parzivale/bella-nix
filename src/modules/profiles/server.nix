# Scope: base for headless servers — deployment target, locale, memory tuning.
# All server hosts should use this. Add host-specific services on top.
{self, ...}: {
  flake.modules.nixos.server = {
    imports = with self.modules.nixos; [
      stylix
      alloy
      deployable
      localization
      zram
    ];
  };
}
