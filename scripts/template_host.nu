use lib

export def main [target_hostname: string]: nothing -> nothing {
  lib template $target_hostname
}
