use bootstrap.nu *
use delete_host.nu *
use template_host.nu *
use deploy_host.nu *
export use lib

export def bnix []: nothing -> nothing {
  help bnix
}

# Bootstraps a new machine to join the fleet
# Will:
# - create host folder
# - format hosts disk
# - create host pubkey
# - setup tailscale client
# - deploy a template config
export def "bnix host bootstrap" [
  target_hostname: string # The name to set the new host as
]: nothing -> nothing {
  bootstrap $target_hostname
}

# Deletes a host from the repo
export def "bnix host delete" [
  target_hostname: string # The host to delete
]: nothing -> nothing {
  delete_host $target_hostname
}

# Creates a new host template for a given hostname
export def "bnix host template" [
  target_hostname: string # The name of the new host
]: nothing -> nothing {
  template_host $target_hostname
}

# Deploys NixOS configurations via deploy-rs.
# Accepts a list of hostnames as arguments or via pipe.
# Defaults to all hosts except bootstrap and the current machine.
# Runs nix flake check once before deploying.
export def "bnix host deploy" [
  ...hosts: string               # Hosts to deploy (optional, defaults to all deployable hosts)
  --dry-activate                 # Build and prepare activation but don't activate
  --no-auto-rollback             # Disable automatic rollback on activation failure
  --no-magic-rollback            # Disable magic rollback
  --fast-connection              # Assume a fast connection (skip key checks)
  --keep-result                  # Keep the nix build result symlink
  --rollback-succeeded           # Mark the rollback as succeeded
  --confirm-timeout: int         # Seconds to wait for confirmation (default: 30)
  --activation-timeout: int      # Seconds to wait for activation (default: 240)
  --ssh-user: string             # SSH user to connect with
  --ssh-opts: string             # Extra options to pass to SSH
  --result-path: string          # Path to store the nix build result
]: [nothing -> nothing, list<string> -> nothing, string -> nothing] {
  let flags = [
    ...(if $dry_activate { [--dry-activate] } else { [] })
    ...(if $no_auto_rollback { [--no-auto-rollback] } else { [] })
    ...(if $no_magic_rollback { [--no-magic-rollback] } else { [] })
    ...(if $fast_connection { [--fast-connection] } else { [] })
    ...(if $keep_result { [--keep-result] } else { [] })
    ...(if $rollback_succeeded { [--rollback-succeeded] } else { [] })
    ...(if $confirm_timeout != null { [--confirm-timeout $confirm_timeout] } else { [] })
    ...(if $activation_timeout != null { [--activation-timeout $activation_timeout] } else { [] })
    ...(if $ssh_user != null { [--ssh-user $ssh_user] } else { [] })
    ...(if $ssh_opts != null { [--ssh-opts $ssh_opts] } else { [] })
    ...(if $result_path != null { [--result-path $result_path] } else { [] })
  ]
  $in | deploy_host ...$hosts --extra-flags $flags
}
