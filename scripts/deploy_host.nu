use lib

export def main [
  ...hosts: string
  --extra-flags: list<string> = []  # Extra flags forwarded from bnix host deploy
]: [nothing -> nothing, list<string> -> nothing, string -> nothing] {
  let current_host = sys host | get hostname
  let piped = $in

  let targets = if ($hosts | is-not-empty) {
    $hosts
  } else if $piped != null {
    $piped | wrap name | get name
  } else {
    ls -s $lib.HOSTS_DIR
      | get name
      | where { |h| $h != "bootstrap" and $h != $current_host }
  }
  | each { |h| $"($lib.PROJECT_ROOT)#($h)" }

  nix flake check $lib.PROJECT_ROOT
  deploy -i --skip-checks --targets ...$targets ...$extra_flags
}
