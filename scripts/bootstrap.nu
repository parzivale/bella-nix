use lib

export def main [target_hostname: string]: nothing -> nothing {
    let target_hostname = $target_hostname
    let user = lib user
    let TARGET_DIR = $"($lib.HOSTS_DIR)/($target_hostname)"
    
    let remote_facter = "/tmp/facter.json"
    let local_facter = $"($TARGET_DIR)/facter.json"

    let first_pass_known_hosts = $"(lib artifacts)/known_hosts_1" 

    if ($TARGET_DIR | path exists) {
        print $"==> Error: Host directory ($TARGET_DIR) already exists."
        exit 1
    }
    
    lib prompt_key_local

    print "==> Adding key to agent\n"
    ssh-add -K
    print $"==> Checking for ($lib.BOOTSTRAP_HOSTNAME)...\n"

    try {
        ping -c 1 -W 2 -q $lib.BOOTSTRAP_HOSTNAME | ignore
        print "\n==> Found host\n"
    } catch {
        print "\n==> Error: Host unreachable\n"
        exit 1
    }


    print $"==> Scaffolding ($TARGET_DIR)...\n"
    mkdir $lib.HOSTS_DIR
    cp -r $lib.TEMPLATE_DIR $TARGET_DIR
    let addr = avahi-resolve-host-name $lib.BOOTSTRAP_HOSTNAME | str substring 15.. | str trim
    print "==> Initial ssh connection\n"
    lib ssh_with_opts "echo '==> Connected to host\n'" $user $addr $first_pass_known_hosts
    lib verify $addr $TARGET_DIR $first_pass_known_hosts
    let command = $"ls -s /dev/disk/by-id/ | get name | to text | fzf --header 'Select boot disk' | save -f /tmp/boot_disk; print 'Scanning Hardware'; sudo nixos-facter -o ($remote_facter);"
    lib ssh_with_opts $command $user $addr $first_pass_known_hosts
    lib scp_down $remote_facter $local_facter $user $addr $first_pass_known_hosts
    lib scp_down /tmp/boot_disk $"($TARGET_DIR)/boot_disk" $user $addr $first_pass_known_hosts
    nixos-anywhere --flake $"(lib.PROJECT_ROOT)/flake.nix#bootstrap" --target-host $lib.BOOTSTRAP_HOSTNAME
    
}
