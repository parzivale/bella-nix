use bootstrap.nu *

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
export def "bnix bootstrap" [
  target_hostname: string # The name to set the new host as
]: nothing -> nothing {
  bootstrap $target_hostname
}
