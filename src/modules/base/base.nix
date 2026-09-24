{ inputs, ... }:
{
  # Only modules that evaluate under any class belong here: `base` is imported
  # by nixos and finix hosts alike. Taking the import list from
  # `modules.generic` keeps that honest — naming a class-specific module is a
  # missing-attribute error rather than a failure on the first finix host.
  flake.modules.generic.base = {
    imports = with inputs.self.modules.generic; [
      constants
      preserve
      keybinds
      startup
    ];
  };
}
