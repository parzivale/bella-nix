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

# Deploys a configuration to a known host
export def "bnix host deploy" []: nothing -> nothing {
  deploy_host
} 
