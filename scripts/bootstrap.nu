use lib

export def main [target_hostname: string]: nothing -> nothing {
    let target_hostname = $target_hostname
    let user = lib user
    let TARGET_DIR = $"($lib.HOSTS_DIR)/($target_hostname)"
    
    let remote_facter_file = "/tmp/facter.json"
    let local_facter_file = $"($TARGET_DIR)/facter.json"
    
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

    if ($TARGET_DIR | path exists) {
        print $"==> Error: Host directory ($TARGET_DIR) already exists."
        exit 1
    }

    print $"==> Scaffolding ($TARGET_DIR)...\n"
    mkdir $lib.HOSTS_DIR
    cp -r $lib.TEMPLATE_DIR $TARGET_DIR
    let addr = avahi-resolve-host-name $lib.BOOTSTRAP_HOSTNAME | str substring 15.. | str trim
    print "==> Initial ssh connection\n"
    lib ssh_with_opts "echo '==> Connected to host\n'" $user $addr false
    lib verify $addr $TARGET_DIR false
    lib ssh_with_opts $"sudo disktui; echo 'Scanning Hardware'; sudo nixos-facter > ($remote_facter_file)" $user $addr false
    lib scp_down $remote_facter_file $local_facter_file $user $addr false
   
    
    let devices = open $local_facter_file | get hardware.disk
}
